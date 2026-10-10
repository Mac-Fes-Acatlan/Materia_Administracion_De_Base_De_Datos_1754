-- ---------------------------------------------------------------------
-- 1. ¿Cómo evolucionan las ventas mes a mes?
--    Órdenes, ingresos, flete y ticket promedio.
-- ---------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', NULLIF(o.order_purchase_timestamp, '')::timestamp)::date         AS mes,
    COUNT(DISTINCT o.order_id)                                    AS ordenes,
    ROUND(SUM(oi.price::numeric), 2)                                       AS ingresos,
    ROUND(SUM(oi.freight_value::numeric), 2)                               AS flete,
    ROUND(SUM(oi.price::numeric) / COUNT(DISTINCT o.order_id), 2)          AS ticket_promedio
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- 2. ¿Cuáles son las 10 categorías que más ingresos generan?
-- ---------------------------------------------------------------------
SELECT
    COALESCE(t.product_category_name_english,
             p.product_category_name,
             'sin_categoria')                                     AS categoria,
    COUNT(DISTINCT oi.order_id)                                   AS ordenes,
    COUNT(*)                                                      AS unidades,
    ROUND(SUM(oi.price::numeric), 2)                                       AS ingresos,
    ROUND(AVG(oi.price::numeric), 2)                                       AS precio_promedio,
    ROUND(100.0 * SUM(oi.price::numeric) / SUM(SUM(oi.price::numeric)) OVER (), 2)  AS pct_del_total
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN products p ON p.product_id = oi.product_id
LEFT JOIN product_category_name_translation t
       ON t.product_category_name = p.product_category_name
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1
ORDER BY ingresos DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 3. ¿Quiénes son los 10 vendedores más importantes y qué tan
--    satisfechos quedan sus clientes?
-- ---------------------------------------------------------------------
SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,
    COUNT(DISTINCT oi.order_id)                                   AS ordenes,
    ROUND(SUM(oi.price::numeric), 2)                                       AS ingresos,
    ROUND(100.0 * SUM(oi.price::numeric) / SUM(SUM(oi.price::numeric)) OVER (), 2)  AS pct_del_total,
    ROUND(AVG(r.review_score::numeric), 2)                                 AS review_promedio
FROM order_items oi
JOIN orders o   ON o.order_id = oi.order_id
JOIN sellers s  ON s.seller_id = oi.seller_id
LEFT JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY s.seller_id, s.seller_city, s.seller_state
ORDER BY ingresos DESC
LIMIT 10;


-- ---------------------------------------------------------------------
-- 4. ¿Dónde están los clientes que más compran? (por estado)
-- ---------------------------------------------------------------------
SELECT
    c.customer_state                                              AS estado,
    COUNT(DISTINCT c.customer_unique_id)                          AS clientes,
    COUNT(DISTINCT o.order_id)                                    AS ordenes,
    ROUND(SUM(oi.price::numeric), 2)                                       AS ingresos,
    ROUND(SUM(oi.price::numeric) / COUNT(DISTINCT o.order_id), 2)          AS ticket_promedio,
    ROUND(AVG(oi.freight_value::numeric), 2)                               AS flete_promedio_por_item
FROM orders o
JOIN customers c    ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1
ORDER BY ingresos DESC;


-- ---------------------------------------------------------------------
-- 5. Desempeño logístico: tiempo de entrega y % de entregas tardías
--    por mes.
-- ---------------------------------------------------------------------
SELECT
    DATE_TRUNC('month', NULLIF(o.order_purchase_timestamp, '')::timestamp)::date         AS mes,
    COUNT(*)                                                      AS entregas,
    ROUND(AVG(EXTRACT(EPOCH FROM (NULLIF(o.order_delivered_customer_date, '')::timestamp
                                  - NULLIF(o.order_purchase_timestamp, '')::timestamp)) / 86400)::numeric, 1)
                                                                  AS dias_promedio_entrega,
    ROUND(AVG(EXTRACT(EPOCH FROM (NULLIF(o.order_estimated_delivery_date, '')::timestamp
                                  - NULLIF(o.order_delivered_customer_date, '')::timestamp)) / 86400)::numeric, 1)
                                                                  AS dias_de_holgura_vs_estimado,
    ROUND(100.0 * COUNT(*) FILTER (
              WHERE NULLIF(o.order_delivered_customer_date, '')::timestamp > NULLIF(o.order_estimated_delivery_date, '')::timestamp)
          / COUNT(*), 2)                                          AS pct_entregas_tardias
FROM orders o
WHERE o.order_status = 'delivered'
  AND NULLIF(o.order_delivered_customer_date, '')::timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- 6. ¿Cuánto afecta una entrega tardía a la satisfacción del cliente?
-- ---------------------------------------------------------------------
SELECT
    CASE
        WHEN NULLIF(o.order_delivered_customer_date, '')::timestamp > NULLIF(o.order_estimated_delivery_date, '')::timestamp
            THEN 'Tardía'
        ELSE 'A tiempo'
    END                                                           AS tipo_entrega,
    COUNT(*)                                                      AS reviews,
    ROUND(AVG(r.review_score::numeric), 2)                                 AS score_promedio,
    ROUND(100.0 * COUNT(*) FILTER (WHERE r.review_score::numeric <= 2)
          / COUNT(*), 2)                                          AS pct_reviews_negativas
FROM orders o
JOIN order_reviews r ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND NULLIF(o.order_delivered_customer_date, '')::timestamp IS NOT NULL
GROUP BY 1
ORDER BY 1;


-- ---------------------------------------------------------------------
-- 7. ¿Cómo pagan los clientes? Mix de métodos de pago y cuotas.
-- ---------------------------------------------------------------------
SELECT
    op.payment_type,
    COUNT(DISTINCT op.order_id)                                   AS ordenes,
    ROUND(SUM(op.payment_value::numeric), 2)                               AS valor_total,
    ROUND(100.0 * SUM(op.payment_value::numeric)
          / SUM(SUM(op.payment_value::numeric)) OVER (), 2)                AS pct_del_valor,
    ROUND(AVG(op.payment_value::numeric), 2)                               AS pago_promedio,
    ROUND(AVG(op.payment_installments::numeric), 1)                        AS cuotas_promedio
FROM order_payments op
JOIN orders o ON o.order_id = op.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1
ORDER BY valor_total DESC;


-- ---------------------------------------------------------------------
-- 8. Retención: ¿qué porcentaje de clientes vuelve a comprar?
-- ---------------------------------------------------------------------
WITH pedidos_por_cliente AS (
    SELECT
        c.customer_unique_id,
        COUNT(DISTINCT o.order_id) AS num_ordenes
    FROM orders o
    JOIN customers c ON c.customer_id = o.customer_id
    WHERE o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY 1
)
SELECT
    COUNT(*)                                                      AS clientes_totales,
    COUNT(*) FILTER (WHERE num_ordenes > 1)                       AS clientes_recurrentes,
    ROUND(100.0 * COUNT(*) FILTER (WHERE num_ordenes > 1)
          / COUNT(*), 2)                                          AS pct_recompra,
    ROUND(AVG(num_ordenes), 3)                                    AS ordenes_promedio_por_cliente
FROM pedidos_por_cliente;


-- ---------------------------------------------------------------------
-- 9. Embudo comercial: de lead calificado (MQL) a vendedor cerrado,
--    por canal de origen.
-- ---------------------------------------------------------------------
SELECT
    COALESCE(lq.origin, 'unknown')                                AS origen,
    COUNT(*)                                                      AS mqls,
    COUNT(lc.mql_id)                                              AS cerrados,
    ROUND(100.0 * COUNT(lc.mql_id) / COUNT(*), 2)                 AS tasa_conversion_pct,
    ROUND(AVG(NULLIF(lc.won_date, '')::date - NULLIF(lq.first_contact_date, '')::date), 1) AS dias_promedio_cierre
FROM leads_qualified lq
LEFT JOIN leads_closed lc ON lc.mql_id = lq.mql_id
GROUP BY 1
ORDER BY mqls DESC;


-- ---------------------------------------------------------------------
-- 10. ¿Qué canales traen a los vendedores que más venden?
--     Ingresos generados por vendedores captados, por origen del lead
--     y segmento de negocio.
-- ---------------------------------------------------------------------
SELECT
    COALESCE(lq.origin, 'unknown')                                AS origen,
    lc.business_segment,
    COUNT(DISTINCT lc.seller_id)                                  AS vendedores_captados,
    COUNT(DISTINCT oi.order_id)                                   AS ordenes,
    ROUND(SUM(oi.price::numeric), 2)                                       AS ingresos,
    ROUND(SUM(oi.price::numeric) / NULLIF(COUNT(DISTINCT lc.seller_id), 0), 2)
                                                                  AS ingresos_por_vendedor
FROM leads_closed lc
JOIN leads_qualified lq ON lq.mql_id = lc.mql_id
JOIN order_items oi     ON oi.seller_id = lc.seller_id
JOIN orders o           ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY 1, 2
ORDER BY ingresos DESC;