"""A liveness prober dag for monitoring composer.googleapis.com/environment/healthy."""
import datetime

from airflow import DAG

# pylint: disable=g-import-not-at-top
try:
  from airflow.providers.standard.operators.bash import BashOperator
except ImportError:
  from airflow.operators.bash_operator import BashOperator
# pylint: enable=g-import-not-at-top

default_args = {
    'start_date': datetime.datetime(2000, 1, 1),
    'retries': 1,
    'retry_delay': datetime.timedelta(minutes=5),
}

dag = DAG(
    'airflow_monitoring',
    default_args=default_args,
    description='liveness monitoring dag',
    schedule='*/10 * * * *',
    max_active_runs=2,
    catchup=False,
    dagrun_timeout=datetime.timedelta(minutes=10),
)

# priority_weight has type int in Airflow DB, uses the maximum.
t1 = BashOperator(
    task_id='echo',
    bash_command='echo test',
    dag=dag,
    depends_on_past=False,
    priority_weight=2**31 - 1,
    do_xcom_push=False)