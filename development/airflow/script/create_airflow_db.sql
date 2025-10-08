-- Crear usuario específico para Airflow
CREATE USER airflow WITH PASSWORD 'snSwXe4v';

-- Crear base de datos para Airflow, asignando como propietario al nuevo usuario
CREATE DATABASE db_airflow OWNER airflow;

-- Otorgar privilegios de conexión y permisos básicos
GRANT ALL PRIVILEGES ON DATABASE db_airflow TO airflow;