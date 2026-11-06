-- ==========================================
-- 1. HARDENING
-- ==========================================
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE db_acatlan FROM PUBLIC;


-- ==========================================
-- 2. CATÁLOGO DE ROLES 
-- ==========================================

-- Rol 1: Solo Lectura
CREATE ROLE readonly;

-- Rol 2: Lectura y Escritura Estándar
CREATE ROLE readwrite;

-- Rol 3: Rol con Superpoderes (Lectura, Escritura, Create, Update, Delete, Truncate y Drop)
CREATE ROLE super_admin_app;


-- ==========================================
-- 3. GRANTS (Asignación de permisos a los roles)
-- ==========================================

-- A. Permisos para el rol: readonly
GRANT CONNECT ON DATABASE db_acatlan TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO readonly;

-- B. Permisos para el rol: readwrite
GRANT CONNECT ON DATABASE db_acatlan TO readwrite;
GRANT USAGE, CREATE ON SCHEMA public TO readwrite;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO readwrite;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO readwrite;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE ON SEQUENCES TO readwrite;

-- C. Permisos para el rol: super_admin_app
GRANT CONNECT ON DATABASE db_acatlan TO super_admin_app;
GRANT USAGE, CREATE ON SCHEMA public TO super_admin_app;
GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER ON ALL TABLES IN SCHEMA public TO super_admin_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE, TRUNCATE, TRIGGER ON TABLES TO super_admin_app;
GRANT USAGE, SELECT, UPDATE ON ALL SEQUENCES IN SCHEMA public TO super_admin_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT, UPDATE ON SEQUENCES TO super_admin_app;


-- ==========================================
-- 4. ASIGNACIÓN A USUARIOS CON LA CREACIÓN
-- ==========================================

-- Crear los usuarios finales con sus contraseñas
CREATE USER reporting_user1 WITH PASSWORD 'tu_password_seguro';
CREATE USER app_user1 WITH PASSWORD 'tu_password_seguro';
CREATE USER super_user1 WITH PASSWORD 'tu_password_seguro';

-- Asignarles el rol correspondiente ("el chaleco" de permisos)
GRANT readonly TO reporting_user1;
GRANT readwrite TO app_user1;
GRANT super_admin_app TO super_user1;