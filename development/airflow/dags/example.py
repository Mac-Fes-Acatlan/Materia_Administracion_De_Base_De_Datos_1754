from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.postgres.operators.postgres import PostgresOperator
from airflow.operators.python_operator import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.dummy import DummyOperator

# Definición del DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    dag_id='postgres_example_dag',
    default_args=default_args,
    description='Ejemplo simple de DAG con PostgresOperator',
    schedule_interval='@daily',  # Corre una vez al día
    start_date=datetime(2025, 1, 1),
    catchup=False,
    tags=['postgres', 'example'],
) as dag:

    # Tarea 1: Crear tabla si no existe
    create_table = PostgresOperator(
        task_id='create_table',
        postgres_conn_id='postgres_default',  # Debe existir en Airflow Connections
        sql="""
        CREATE TABLE IF NOT EXISTS example_table (
            id SERIAL PRIMARY KEY,
            name VARCHAR(50),
            created_at TIMESTAMP DEFAULT NOW()
        );
        """,
    )

    # Tarea 2: Insertar un registro
    insert_row = PostgresOperator(
        task_id='insert_row',
        postgres_conn_id='postgres_default',
        sql="""
        INSERT INTO example_table (name)
        VALUES ('Registro de ejemplo');
        """,
    )

    insert_row_two = PostgresOperator(
        task_id='insert_row_two',
        postgres_conn_id='postgres_default',
        sql="""
        INSERT INTO example_table (name)
        SELECT pg_size_pretty(pg_database_size(current_database()));
        """,
    )

    # Tarea 3: Consultar datos
    select_data = PostgresOperator(
        task_id='select_data',
        postgres_conn_id='postgres_default',
        sql="SELECT * FROM example_table;",
    )

    python_task = PythonOperator(
        task_id="python_task",
        python_callable=lambda: print('Hi from python operator'),

    )

    bash_task = BashOperator(
        task_id="bash_task",
        bash_command='echo "Hi from bash operator"',
        # env: Optional[Dict[str, str]] = None,
        # output_encoding: str = 'utf-8',
        # skip_exit_code: int = 99,
    )

    end_worflow = DummyOperator(
        task_id="end_worflow",
        # ui_color='#e8f7e4'
    )

    # Flujo de dependencias
    create_table >> [insert_row,insert_row_two,python_task,bash_task] 
    insert_row >> end_worflow
    insert_row_two >> end_worflow
    python_task >> end_worflow
    bash_task >> end_worflow
    end_worflow
