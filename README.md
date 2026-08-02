# 🗄️ Administración de Bases de Datos — Grupo 1754

Repositorio oficial de la asignatura **Administración de Bases de Datos** (Grupo 1754) de la Licenciatura en **Matemáticas Aplicadas y Computación (MAC)** de la **Facultad de Estudios Superiores Acatlán (UNAM)**.

Este repositorio concentra el material del curso, incluyendo prácticas, ejercicios, proyectos y un entorno de desarrollo completamente contenerizado basado en **Docker** para facilitar el aprendizaje de la administración de bases de datos.

---

# 📋 Descripción del Curso

El objetivo de la asignatura es que el estudiante adquiera los conocimientos necesarios para instalar, administrar, monitorear, respaldar y optimizar Sistemas Gestores de Bases de Datos (SGBD), utilizando herramientas modernas empleadas en entornos profesionales.

## Temas principales

- Arquitectura de Sistemas Gestores de Bases de Datos.
- Administración de usuarios, roles y privilegios.
- Seguridad, respaldo y recuperación de información.
- Optimización de consultas e índices.
- Monitoreo del rendimiento del sistema.
- Automatización de tareas administrativas.
- Integración con herramientas de análisis de datos.

---

# 🏗️ Entorno de Desarrollo

El proyecto utiliza **Docker Compose** para desplegar automáticamente todos los servicios necesarios para las prácticas del curso.

| Servicio | Descripción | Puerto |
|----------|-------------|:------:|
| 🐘 **PostgreSQL 16** | Motor principal de base de datos. | **5432** |
| ⚡ **pgLoader** | Carga y migración automática de datos mediante el script `database/creacion.load`. | — |
| 📈 **Prometheus** | Recolección de métricas del sistema. | **9090** |
| 📊 **Grafana** | Visualización de métricas y dashboards. | **3000** |
| 🔥 **PySpark + Jupyter Notebook** | Procesamiento de datos y análisis utilizando Apache Spark. | **8888** |
| 🛠️ **Databasus** | Interfaz web para administración de PostgreSQL. | **4005** |
| ☁️ **Ministack** | Emulador local de servicios AWS. | **4566** |
| ⚙️ **Stackport** | Interfaz gráfica para interactuar con Ministack. | **8080** |

Todos los servicios se encuentran conectados mediante la red Docker **`fes-acatlan`**.

---

# 📂 Estructura del Repositorio

```text
.
├── database/
│   └── creacion.load          # Script de carga ejecutado por pgLoader
│
├── development/
│   └── jupyter_notebook/      # Notebooks y código PySpark
│
├── databasus-data/            # Persistencia de Databasus
├── tablespaces/               # Tablespaces persistentes de PostgreSQL
│
├── Dockerfile                 # Imagen para PySpark + Jupyter
├── docker-compose.yml         # Definición de todos los servicios
├── prometheus.yml             # Configuración de Prometheus
├── Launcher.sh                # Script de inicialización del entorno
├── .env                       # Variables de entorno (local)
└── README.md
```

---

# 📋 Requisitos Previos

Antes de iniciar, instala las siguientes herramientas:

- Docker Desktop **o** Docker Engine + Docker Compose v2.
- Git.

---

# 🚀 Configuración del Proyecto

## 1. Clonar el repositorio

```bash
git clone https://github.com/Mac-Fes-Acatlan/Materia_Administracion_De_Base_De_Datos_1754.git

cd Materia_Administracion_De_Base_De_Datos_1754
```

---

## 2. Configurar el archivo `.env`

Crea un archivo llamado **`.env`** en la raíz del proyecto con el siguiente contenido:

```env
# PostgreSQL
POSTGRES_USER=acatlan
POSTGRES_PASSWORD=8g4izJPX
POSTGRES_DB=db_acatlan

# Ruta ABSOLUTA donde se encuentra la carpeta development/jupyter_notebook
PATH_JUPYTER=/ruta/completa/al/proyecto/development/jupyter_notebook

# Token para acceder a Jupyter Notebook
JUPYTER_TOKEN=6nMG38Df
```

> **Importante**
>
> La variable `PATH_JUPYTER` debe contener la **ruta absoluta** hacia la carpeta `development/jupyter_notebook` de tu computadora.

Ejemplo:

**macOS**

```text
/Users/usuario/Documents/Materia_Administracion_De_Base_De_Datos_1754/development/jupyter_notebook
```

**Linux**

```text
/home/usuario/Materia_Administracion_De_Base_De_Datos_1754/development/jupyter_notebook
```

**Windows (WSL)**

```text
/mnt/c/Users/usuario/Documents/Materia_Administracion_De_Base_De_Datos_1754/development/jupyter_notebook
```

---

## 3. Iniciar el entorno

Una vez configurado el archivo `.env`, ejecuta:

```bash
source Launcher.sh
```

El script iniciará automáticamente todos los servicios del entorno.

---

# 🌐 Servicios Disponibles

Una vez iniciado el entorno podrás acceder a:

| Servicio | URL |
|----------|-----|
| Jupyter Notebook | http://localhost:8888 |
| Grafana | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Databasus | http://localhost:4005 |
| Stackport | http://localhost:8080 |
| Ministack | http://localhost:4566 |

---

# 🐳 Servicios Docker

El entorno levanta los siguientes contenedores:

- PostgreSQL 16
- pgLoader
- Prometheus
- Grafana
- PySpark + Jupyter Notebook
- Databasus
- Ministack
- Stackport

Todos los datos persistentes se almacenan en directorios del proyecto para evitar pérdidas de información al reiniciar los contenedores.