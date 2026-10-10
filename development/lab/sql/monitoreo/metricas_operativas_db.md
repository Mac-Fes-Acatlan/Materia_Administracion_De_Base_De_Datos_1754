# Métricas de PostgreSQL (versión simple)

2 métricas por categoría, todas de **solo lectura** (no modifican nada), con soluciones breves.

---

## 1. Query Response Time

**Monitoreo en vivo: todo lo que la base de datos está ejecutando ahora**
```sql
SELECT pid,
       usename,
       application_name,
       client_addr,
       state,
       now() - query_start AS duracion,
       wait_event_type,
       wait_event,
       query
FROM pg_stat_activity
WHERE state = 'active'
  AND pid <> pg_backend_pid()
ORDER BY duracion DESC;
```
Para ver también las sesiones abiertas que no ejecutan nada (`idle`, `idle in transaction`), quita la línea `state = 'active'`. Si `wait_event` trae un valor, la consulta está esperando algo (un lock, disco, etc.).

**Métrica 1: Consultas que llevan más de 30 segundos ejecutándose**
```sql
SELECT pid, usename, now() - query_start AS duracion, query
FROM pg_stat_activity
WHERE state = 'active'
  AND pid <> pg_backend_pid()
  AND now() - query_start > interval '30 seconds'
ORDER BY duracion DESC;
```

**Métrica 2: Tablas con muchos escaneos secuenciales (consultas sin índice)**
```sql
SELECT relname, seq_scan, idx_scan, seq_tup_read
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC
LIMIT 10;
```

**Soluciones**
- Crea índices en las columnas que usas en `WHERE` y `JOIN`.
- Revisa la consulta con `EXPLAIN ANALYZE`.
- Evita `SELECT *`.

---

## 2. Connection Pool Usage

**Métrica 1: Conexiones por estado**
```sql
SELECT state, COUNT(*) AS total
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY state;
```

**Métrica 2: Porcentaje de uso del máximo de conexiones**
```sql
SELECT COUNT(*) AS actuales,
       current_setting('max_connections')::int AS maximo,
       ROUND(100.0 * COUNT(*) / current_setting('max_connections')::int, 2) AS pct_uso
FROM pg_stat_activity;
```

**Soluciones**
- Usa un pooler como PgBouncer.
- Cierra conexiones que la aplicación deja abiertas.
- No subas `max_connections` sin revisar la memoria disponible.

---

## 3. Memory Usage

**Métrica 1: Cache hit ratio (debe ser mayor a 99%)**
```sql
SELECT datname,
       ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_pct
FROM pg_stat_database
WHERE datname = current_database();
```

**Métrica 2: Archivos temporales (consultas que no caben en memoria)**
```sql
SELECT datname, temp_files, pg_size_pretty(temp_bytes) AS tamano_temp
FROM pg_stat_database
ORDER BY temp_bytes DESC;
```

**Soluciones**
- Aumenta `shared_buffers` (alrededor del 25% de la RAM).
- Ajusta `work_mem` con cuidado, porque se usa por operación y por conexión.
- Agrega índices para reducir ordenamientos grandes.

---

## 4. Disk Usage

**Métrica 1: Tamaño de la base de datos y de las 10 tablas más grandes**
```sql
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamano_bd;

SELECT relname AS tabla,
       pg_size_pretty(pg_total_relation_size(relid)) AS tamano_total
FROM pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 10;
```

**Métrica 2: Tuplas muertas (espacio desperdiciado)**
```sql
SELECT relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_user_tables
ORDER BY n_dead_tup DESC
LIMIT 10;
```

**Soluciones**
- Ejecuta `VACUUM ANALYZE` en las tablas con muchas tuplas muertas.
- Archiva o elimina datos históricos que ya no uses.
- Configura una alerta cuando el disco pase del 80%.

---

## 5. Locks

**Métrica 1: Consultas bloqueadas y quién las bloquea**
```sql
SELECT bloqueada.pid   AS pid_bloqueada,
       bloqueadora.pid AS pid_bloqueadora,
       bloqueada.query AS query_bloqueada
FROM pg_stat_activity bloqueada
JOIN pg_stat_activity bloqueadora
  ON bloqueadora.pid = ANY(pg_blocking_pids(bloqueada.pid));
```

**Métrica 2: Deadlocks acumulados**
```sql
SELECT datname, deadlocks
FROM pg_stat_database
WHERE deadlocks > 0;
```

**Soluciones**
- Mantén las transacciones cortas.
- Accede a las tablas siempre en el mismo orden.
- Si es urgente, termina la sesión bloqueadora: `SELECT pg_terminate_backend(<pid>);`

---

## 6. Transactions

**Métrica 1: Commits, rollbacks y porcentaje de rollbacks**
```sql
SELECT xact_commit,
       xact_rollback,
       ROUND(100.0 * xact_rollback / NULLIF(xact_commit + xact_rollback, 0), 2) AS pct_rollback
FROM pg_stat_database
WHERE datname = current_database();
```

**Métrica 2: Transacciones abiertas por mucho tiempo**
```sql
SELECT pid, usename, now() - xact_start AS duracion, state, query
FROM pg_stat_activity
WHERE xact_start IS NOT NULL
ORDER BY xact_start
LIMIT 10;
```

**Soluciones**
- Si hay muchos rollbacks, revisa los errores de la aplicación en los logs.
- Cierra las transacciones largas: bloquean el vacuum y retienen locks.
- Haz `COMMIT` o `ROLLBACK` apenas termine la operación.

---

## 7. Connections

**Métrica 1: Conexiones por usuario y aplicación**
```sql
SELECT usename, application_name, COUNT(*) AS conexiones
FROM pg_stat_activity
WHERE datname IS NOT NULL
GROUP BY usename, application_name
ORDER BY conexiones DESC;
```

**Métrica 2: Conexiones inactivas por más de 10 minutos**
```sql
SELECT pid, usename, client_addr, now() - state_change AS tiempo_idle
FROM pg_stat_activity
WHERE state = 'idle'
  AND now() - state_change > interval '10 minutes'
ORDER BY tiempo_idle DESC;
```

**Soluciones**
- Identifica qué aplicación abre demasiadas conexiones y reduce su pool.
- Cierra las conexiones inactivas antiguas.
- Limita conexiones por usuario: `ALTER ROLE app_user CONNECTION LIMIT 50;`