import os
import requests

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator
from airflow.providers.google.cloud.operators.bigquery import (BigQueryCreateEmptyTableOperator, 
                                                               BigQueryInsertJobOperator)

# Project Configuration
PROJECT_ID = os.environ.get('MY_PROJECT_ID')
GOOGLE_CONN_ID = os.environ.get('GOOGLE_CONN_ID')
REGION = os.environ.get('REGION')
ZONE = os.environ.get('ZONE')

BUCKET_NAME = os.environ.get('BUCKET')
TEMP_BUCKET_NAME = os.environ.get('TEMP_BUCKET')
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

    # Create staging_table in BigQuery if not exists
    create_staging_table = BigQueryCreateEmptyTableOperator(
        task_id="create_staging_table",
        dataset_id="staging",
        table_id="air_pollution_data",
        schema_fields=[
            {"name": "country", "type": "STRING", "mode": "REQUIRED"},
            {"name": "city", "type": "STRING", "mode": "REQUIRED"},
            {"name": "aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "co_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "co_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ozone_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "ozone_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "no2_aqi_value", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "no2_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "pm25_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "pm25_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "dominant_pollutant", "type": "STRING", "mode": "NULLABLE"}
        ],
        create_disposition='CREATE_IF_NEEDED'
    )

    # Submit PySpark job to Dataproc
    etl_data = DataprocSubmitJobOperator(
        task_id="pyspark_task",
        job=PYSPARK_JOB,
        region=REGION,
        project_id=PROJECT_ID,
        gcp_conn_id="google_cloud_default"
    )

    # Create fact_table in BigQuery if not exists
    create_fact_table = BigQueryCreateEmptyTableOperator(
        task_id="create_fact_table",
        dataset_id="fact",
        table_id="air_pollution_data",
        schema_fields=[
            {"name": "country", "type": "STRING", "mode": "REQUIRED"},
            {"name": "city", "type": "STRING", "mode": "REQUIRED"},
            {"name": "aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "co_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "co_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "ozone_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "ozone_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "no2_aqi_value", "type": "FLOAT64", "mode": "NULLABLE"},
            {"name": "no2_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "pm25_aqi_value", "type": "INT64", "mode": "NULLABLE"},
            {"name": "pm25_aqi_category", "type": "STRING", "mode": "NULLABLE"},
            {"name": "dominant_pollutant", "type": "STRING", "mode": "NULLABLE"}
        ],
        create_disposition='CREATE_IF_NEEDED'
    )

    # Task to write data to BigQuery
    upsert_data = BigQueryInsertJobOperator(
        task_id="upsert_co2_emissions_to_bigquery",
        configuration={
            "query": {
                "query": """
                    MERGE INTO fact.air_pollution_data AS target
                    USING staging.air_pollution_data AS source
                    ON target.country = source.country 
                    AND target.city = source.city
                    WHEN MATCHED THEN
                    UPDATE SET
                        aqi_value = source.aqi_value,
                        aqi_category = source.aqi_category,
                        co_aqi_value = source.co_aqi_value,
                        co_aqi_category = source.co_aqi_category,
                        ozone_aqi_value = source.ozone_aqi_value,
                        ozone_aqi_category = source.ozone_aqi_category,
                        no2_aqi_value = source.no2_aqi_value,
                        no2_aqi_category = source.no2_aqi_category,
                        pm25_aqi_value = source.pm25_aqi_value,
                        pm25_aqi_category = source.pm25_aqi_category,
                        dominant_pollutant = source.dominant_pollutant
                    WHEN NOT MATCHED THEN
                    INSERT (country, city, aqi_value, aqi_category, 
                        co_aqi_value, co_aqi_category, ozone_aqi_value, 
                        ozone_aqi_category, no2_aqi_value, no2_aqi_category, 
                        pm25_aqi_value, pm25_aqi_category, dominant_pollutant)
                    VALUES (source.country, source.city, source.aqi_value,
                        source.aqi_category, source.co_aqi_value, 
                        source.co_aqi_category, source.ozone_aqi_value, 
                        source.ozone_aqi_category, source.no2_aqi_value, 
                        source.no2_aqi_category, source.pm25_aqi_value, 
                        source.pm25_aqi_category, source.dominant_pollutant);
                """,
                "useLegacySql": False,
            }
        },
        location="US",
        gcp_conn_id="google_cloud_default",  # Ensure this connection exists in Airflow
    )

    # Define task dependencies
    download_data >> etl_data >> upsert_data
