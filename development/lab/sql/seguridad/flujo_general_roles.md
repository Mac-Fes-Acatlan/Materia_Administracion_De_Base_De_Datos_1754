Aquí tienes exactamente el mismo diagrama optimizado en formato **Markdown**, utilizando bloques de código para conservar la estructura visual y viñetas limpias para el resto:

```markdown
# FLUJO GENERAL DE SEGURIDAD EN POSTGRESQL

[ USUARIO MAESTRO (postgres) ] 
              │
              ▼  1. Configuración de Seguridad Inicial (Hardening)
┌─────────────────────────────────────────────────────────┐
│ REVOKE CREATE / ALL ON DATABASE FROM PUBLIC;            │
│ (Quita los permisos automáticos que PostgreSQL da)      │
└─────────────────────────────┬───────────────────────────┘
                              │
                              ▼  2. Creación de Roles por Propósito
              ┌───────────────────────────────┐
              │         CREATE ROLE           │
              └───────────────┬───────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
      [ Rol: readonly ]               [ Rol: readwrite ]
              │                               │
              ├─ CONNECT on DB                ├─ CONNECT on DB
              ├─ USAGE on Schema              ├─ USAGE, CREATE on Schema
              ├─ SELECT on Tables             ├─ SELECT, INSERT, UPDATE, DELETE
              └─ ALTER DEFAULT PRIVILEGES     ├─ USAGE on Sequences
                 (Futuras Tablas)             └─ ALTER DEFAULT PRIVILEGES
                                                 (Futuras Tablas y Secuencias)
                              │
                              ▼  3. Creación y Asignación a Usuarios Finales
              ┌───────────────────────────────┐
              │          CREATE USER          │
              └───────────────┬───────────────┘
                              │
       ┌──────────────────────┴──────────────────────┐
       ▼                                             ▼
 [ Usuario: reporting_user1 ]                  [ Usuario: app_user1 ]
       │                                             │
 GRANT readonly TO reporting_user1;           GRANT readwrite TO app_user1;

```