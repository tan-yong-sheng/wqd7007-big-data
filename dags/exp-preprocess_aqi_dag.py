import os
import json

from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.http.operators.http import SimpleHttpOperator
from airflow.providers.google.cloud.operators.dataproc import (
    DataprocCreateBatchOperator,
    DataprocDeleteBatchOperator,
    DataprocGetBatchOperator,
    DataprocListBatchesOperator,
)

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
BIGQUERY_TABLE = f"{PROJECT_ID}.staging.co2_emissions"

## Variables for Python file & Dataset
PYTHON_FILE_LOCATION = f"gs://{DAGS_BUCKET_NAME}/src/scripts/dataproc_gcs_to_gbq_job.py"
DATASET_FILE = f"gs://{BUCKET_NAME}/dataset/global-air-pollution-datasets.csv"

# Start a single node Dataproc Cluster for viewing Persistent History of Spark jobs
DATAPROC_CLUSTER_PATH = f"projects/{PROJECT_ID}/regions/{REGION}/clusters/{DATAPROC_CLUSTER_NAME}"
# for e.g. projects/my-project/regions/my-region/clusters/my-cluster"
SPARK_BIGQUERY_JAR_FILE = "gs://spark-lib/bigquery/spark-bigquery-latest_2.12.jar"

## Variables for Cloud Function trigger to download data from Kaggle
FUNCTION_NAME = "download_and_upload"

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'start_date': datetime(2025, 6, 1),  # Must be in the past
    'retries': 1,
    'retry_delay': timedelta(seconds=50),
}

# DAG definition
with DAG("SparkETL-exp", schedule_interval="@weekly", default_args=default_args) as dag:

    ### ----------------------------------------------------------- ###
    # Part 1 - Run cloud function with SimpleHttpOperator
    download_data = SimpleHttpOperator(
        task_id='download-kaggle-data',
        method='POST',
        http_conn_id='http_default',
        endpoint=FUNCTION_NAME,
        headers={"Content-Type": "application/json"},
        data=json.dumps({
            "bucket-name": BUCKET_NAME,  # passing the bucket name directly
        }),
    )
   
    ## download data via invoking cloud function
    download_data

    ### ----------------------------------------------------------- ###
    # Part 2 - Running workloads with Dataproc serverless    
    create_batch = DataprocCreateBatchOperator(
        task_id="batch_create",
        region=REGION,
        batch={
            "pyspark_batch": {
                "main_python_file_uri": PYTHON_FILE_LOCATION,
                "jar_file_uris": [SPARK_BIGQUERY_JAR_FILE],
            },
            "environment_config": {
                "peripherals_config": {
                    "spark_history_server_config": {
                        "dataproc_cluster": DATAPROC_CLUSTER_PATH,
                    },
                },
            },
        },
        batch_id="batch-create-dataproc",
    )
    list_batches = DataprocListBatchesOperator(
        task_id="list-all-batches",
    )
    get_batch = DataprocGetBatchOperator(
        task_id="get_batch",
        batch_id="batch-create-dataproc",
    )
    delete_batch = DataprocDeleteBatchOperator(
        task_id="delete_batch",
        batch_id="batch-create-dataproc",
    )

    create_batch >> list_batches >> get_batch >> delete_batch

    ### ----------------------------------------------------------- ###
    # please add 'create bigquery table if not exists'
   
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
