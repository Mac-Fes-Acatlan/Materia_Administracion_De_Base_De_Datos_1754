CREATE TABLESPACE ts1 LOCATION '/var/lib/postgresql/tablespaces/ts1';

ALTER TABLE esquema.mi_tabla SET TABLESPACE ts1;

SELECT
    spcname                               AS tablespace,
    PG_SIZE_PRETTY(PG_TABLESPACE_SIZE(spcname)) AS tamanio,
    PG_TABLESPACE_LOCATION(oid)           AS ubicacion
FROM pg_tablespace;

SELECT
    n.nspname                                     AS esquema,
    c.relname                                     AS tabla,
    s.spcname                                     AS tablespace,
    PG_SIZE_PRETTY(PG_TOTAL_RELATION_SIZE(c.oid)) AS tamanio_total
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
JOIN pg_tablespace s ON s.oid = c.reltablespace
WHERE s.spcname = 'ts1'
ORDER BY PG_TOTAL_RELATION_SIZE(c.oid) DESC;