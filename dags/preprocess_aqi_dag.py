import os
import requests

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator

# Project Configuration
PROJECT_ID = os.environ.get('MY_PROJECT_ID')
GOOGLE_CONN_ID = os.environ.get('GOOGLE_CONN_ID')
REGION = os.environ.get('REGION')
ZONE = os.environ.get('ZONE')

BUCKET_NAME = os.environ.get('BUCKET')
TEMP_BUCKET_NAME = os.environ.get('STAGING_BUCKET')
DAGS_BUCKET_NAME = os.environ.get('DAGS_BUCKET')

## Variables for Dataproc jobs
DATAPROC_CLUSTER_NAME = os.environ.get('DATAPROC_CLUSTER_NAME')

## Variables for BigQuery jobs
STAGING_BIGQUERY_TABLE = f"{PROJECT_ID}.staging.air_pollution_data"

## Variables for Python file & Dataset
PYTHON_SCRIPT_FILE = f"gs://{DAGS_BUCKET_NAME}/src/scripts/preprocess_aqi_data/main.py"
DATASET_FILE = f"gs://{BUCKET_NAME}/dataset/"

## Variables for Cloud Function trigger to download data from Kaggle
FUNCTION_NAME = "download_kaggle_data"

# Setup configuration for pyspark job in Dataproc
PYSPARK_JOB = {
    "reference": {"project_id": PROJECT_ID},
    "placement": {"cluster_name": DATAPROC_CLUSTER_NAME},
    "pyspark_job": {
        "main_python_file_uri": PYTHON_SCRIPT_FILE,
        "args": [
            f"--gcs_path={DATASET_FILE}",
            f"--bigquery_table={STAGING_BIGQUERY_TABLE}",
            f"--bucket_name={TEMP_BUCKET_NAME}",
        ],
    },
}

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'start_date': datetime(2025, 6, 1),  # Must be in the past
    'retries': 1,
    'retry_delay': timedelta(seconds=50),
}


def invoke_cloud_function_with_auth(region: str, project_id: str, function_name: str):
    FUNCTION_URL = f"https://{region}-{project_id}.cloudfunctions.net/{function_name}"
    # calling cloud function
    headers = {"Content-Type": "application/json"}
    response = requests.post(FUNCTION_URL, headers=headers)
    response.raise_for_status()
    return response.json()


# DAG definition
with DAG("SparkETL", schedule_interval="@weekly", default_args=default_args) as dag:

    # Part 1 - Run cloud function
    download_data = PythonOperator(
        task_id='invoke_download_kaggle_data_function',
        python_callable=invoke_cloud_function_with_auth,
        op_kwargs = {
            "region": REGION,
            "project_id": PROJECT_ID,
            "function_name": FUNCTION_NAME
        }
    )

    # Submit PySpark job to Dataproc
    t2 = DataprocSubmitJobOperator(
        task_id="pyspark_task",
        job=PYSPARK_JOB,
        region=REGION,
        project_id=PROJECT_ID,
        gcp_conn_id="google_cloud_default"
    )

    # Task to write data to BigQuery
    #t3 = BigQueryInsertJobOperator(
    #    task_id="upsert_co2_emissions_to_bigquery",
    #    configuration={
    #        "query": {
    #            "query": """
    #                MERGE INTO fact.co2_emissions AS target
    #                USING staging.co2_emissions AS source
    #                ON target.make = source.make 
    #                AND target.model = source.model 
    #                AND target.vehicle_class = source.vehicle_class
    #                AND target.engine_size = source.engine_size
    #                AND target.cylinders = source.cylinders
    #                AND target.transmission = source.transmission
    #                AND target.fuel_type = source.fuel_type
    #                AND target.fuel_consumption_city = source.fuel_consumption_city
    #                AND target.fuel_consumption_hwy = source.fuel_consumption_hwy
    #                AND target.fuel_consumption_comb_lkm = source.fuel_consumption_comb_lkm
    #                AND target.fuel_consumption_comb_mpg = source.fuel_consumption_comb_mpg
    #                AND target.co2_emissions = source.co2_emissions
    #                WHEN MATCHED THEN
    #                UPDATE SET
    #                    engine_size = source.engine_size,
    #                    cylinders = source.cylinders,
    #                    transmission = source.transmission,
    #                    fuel_type = source.fuel_type,
    #                    fuel_consumption_city = source.fuel_consumption_city,
    #                    fuel_consumption_hwy = source.fuel_consumption_hwy,
    #                    fuel_consumption_comb_lkm = source.fuel_consumption_comb_lkm,
    #                    fuel_consumption_comb_mpg = source.fuel_consumption_comb_mpg,
    #                    co2_emissions = source.co2_emissions
    #                WHEN NOT MATCHED THEN
    #                INSERT (make, model, vehicle_class, engine_size, cylinders, 
    #                    transmission, fuel_type, fuel_consumption_city, 
    #                    fuel_consumption_hwy, fuel_consumption_comb_lkm, 
    #                    fuel_consumption_comb_mpg, co2_emissions)
    #                VALUES (source.make, source.model, source.vehicle_class,
    #                    source.engine_size, source.cylinders, source.transmission, 
    #                    source.fuel_type, source.fuel_consumption_city, 
    #                    source.fuel_consumption_hwy, source.fuel_consumption_comb_lkm, 
    #                    source.fuel_consumption_comb_mpg, source.co2_emissions);
    #            """,
    #            "useLegacySql": False,
    #        }
    #    },
    #    location="US",
    #    gcp_conn_id="google_cloud_default",  # Ensure this connection exists in Airflow
    #)

    # Define task dependencies
    download_data >> t2 # >> t3