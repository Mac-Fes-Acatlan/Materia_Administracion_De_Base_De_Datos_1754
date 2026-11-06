EXPLAIN ANALYZE
SELECT 
    c.customer_state,
    COUNT(o.order_id) AS total_ordenes,
    SUM(p.payment_value) AS recaudo_total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_payments p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state;

CREATE INDEX idx_orders_status ON orders(order_status);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_payments_order_id ON order_payments(order_id);

EXPLAIN ANALYZE
SELECT 
    COALESCE(t.product_category_name_english, p.product_category_name) AS categoria,
    COUNT(oi.order_item_id) AS total_vendidos,
    SUM(oi.price) AS ingresos_categoria
FROM order_items oi
JOIN products p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY categoria
ORDER BY ingresos_categoria DESC;

CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_products_category ON products(product_category_name);
CREATE INDEX idx_translation_category ON product_category_name_translation(product_category_name);

EXPLAIN ANALYZE
SELECT 
    s.seller_id,
    s.seller_city,
    AVG(r.review_score) AS promedio_calificacion,
    COUNT(r.review_id) AS total_resenas
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN order_reviews r ON o.order_id = r.order_id
GROUP BY s.seller_id, s.seller_city
HAVING COUNT(r.review_id) > 5
ORDER BY promedio_calificacion DESC;

CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_seller_id ON order_items(seller_id);
CREATE INDEX idx_order_reviews_order_id ON order_reviews(order_id);
CREATE INDEX idx_sellers_id ON sellers(seller_id);