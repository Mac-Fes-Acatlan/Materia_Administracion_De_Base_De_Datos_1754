from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

# Configuración básica del DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'retries': 1,
}

with DAG(
    dag_id='ejemplo_replica',
    default_args=default_args,
    description='DAG para ejecutar pg_dump desde Airflow en contenedor Postgres',
    schedule_interval=None,
    start_date=datetime(2025, 11, 4),
    catchup=False,
) as dag:

    dump_command = """
    docker exec 275dbe4e6e8a pg_dump -U acatlan -F c -d db_acatlan -f /var/lib/postgresql/backups/completo/db_acatlan.dump
    """

    backup_task = BashOperator(
        task_id='backup_postgres',
        bash_command=dump_command,
    )

    backup_task
