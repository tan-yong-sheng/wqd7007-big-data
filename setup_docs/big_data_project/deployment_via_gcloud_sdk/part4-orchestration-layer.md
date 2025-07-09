# Part 4 - Orchestration Layer : Setup Google Cloud Composer

## Setting Up Google Cloud Composer Environment to orchestrate ETL Pipeline

This guide outlines the steps to create a Cloud Composer environment for orchestrating ETL workflows using Airflow.

Prerequisites
-------------

1.  Google Cloud Platform account with billing enabled
2.  Google Cloud Shell
3.  Existing Cloud Function setup shown in Part 1
4.  Existing Dataproc cluster setup shown in Part 2
5.  Required APIs enabled in your GCP project, in Part 1 and Part 2

Step 1: Environment Setup
-------------------------

The commands are executed under the cloud shell terminal

![](/images/cloud-shell.png)

*   Set environment variables in Cloud Shell:

```bash
export PROJECT_ID=gp-461213
export REGION=us-central1
export ZONE=us-central1-f
export DATAPROC_CLUSTER_NAME=air-quality-cluster
export BUCKET=air-pollution-data-my
export STAGING_BUCKET=staging-air-pollution-data-my
export TEMP_BUCKET=temp-air-pollution-data-my
export DATAPROC_CLUSTER_NAME=air-qualiterty-cluster
export DAGS_BUCKET=us-central1-airflow-bucket
export COMPOSER_ENV_NAME=airflow
export SERVICE_ACCOUNT_EMAIL=1000028997311-compute@developer.gserviceaccount.com
```

Step 2: Enable Required APIs
----------------------------

```bash
> gcloud services enable composer.googleapis.com
```

Step 3: Create Cloud Composer Environment
-----------------------------------------

*   Deploy the Composer environment with configurations:

```bash
> gcloud composer environments create ${COMPOSER_ENV_NAME} \
  --project ${PROJECT_ID} \
  --location ${REGION} \
  --environment-size small \
  --image-version composer-3-airflow-2.9.3 \
  --env-variables=MY_PROJECT_ID=${PROJECT_ID},REGION=${REGION},ZONE=${ZONE},DATAPROC_CLUSTER_NAME=${DATAPROC_CLUSTER_NAME},BUCKET=${BUCKET},TEMP_BUCKET=${TEMP_BUCKET},DAGS_BUCKET=${DAGS_BUCKET} \
  --storage-bucket=${DAGS_BUCKET}
```

This will start a composer instance with following environment variables:
![image](/images/composer-startup.png)



Step 4: Configure Dataproc Integration
--------------------------------------

Move to Dataproc's script we've written earlier in Part 2 at `**src/scripts/preprocess_aqi_data/main.py**` to the the Composer's GCS bucket:

```bash
> gsutil cp src/scripts/preprocess_aqi_data/main.py gs://${DAGS_BUCKET}/src/scripts/preprocess_aqi_data/main.py
```

Step 5: Deploy DAG
------------------

*   Create the DAG file:

```bash
nano dags/preprocess_aqi_dag.py
```

Add the following Python Code, as it is a DAG script for Google Cloud Composer

```python
import os
import requests

from datetime import datetime, timedelta
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.dataproc import DataprocSubmitJobOperator
from airflow.providers.google.cloud.operators.bigquery import (BigQueryCreateEmptyTableOperator, 
                                                               BigQueryInsertJobOperator)

# Google Cloud authentication imports
from google.auth.transport.requests import Request
from google.oauth2 import service_account
import google.auth
from google.auth import impersonated_credentials

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
    """
    Invoke a Cloud Function with proper authentication using identity tokens.
    """
    # Import all required modules at the beginning of the function
    from google.auth.transport.requests import Request
    from google.oauth2 import service_account
    from google.auth import jwt
    import google.auth.compute_engine
    import requests as std_requests
    
    # Use the actual Cloud Run URL from terraform output
    FUNCTION_URL = "https://download-kaggle-data-rimwezr5ma-uc.a.run.app"
    
    try:
        # Get default credentials (Composer service account)
        credentials, _ = google.auth.default()
        
        # Check if we're using compute engine credentials (which is the case in Composer)
        if isinstance(credentials, google.auth.compute_engine.Credentials):
            # For compute engine, we need to get an identity token with the service URL as audience
            # Use the metadata server to get an identity token
            metadata_server_url = "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/identity"
            headers = {"Metadata-Flavor": "Google"}
            params = {"audience": FUNCTION_URL, "format": "full"}
            
            print(f"Getting identity token for audience: {FUNCTION_URL}")
            token_response = std_requests.get(metadata_server_url, headers=headers, params=params)
            token_response.raise_for_status()
            identity_token = token_response.text
            
            print(f"Successfully obtained identity token")
            
        else:
            # Fallback for other credential types
            auth_request = Request()
            credentials.refresh(auth_request)
            identity_token = credentials.token
        
        # Make authenticated request with identity token
        headers = {
            "Authorization": f"Bearer {identity_token}",
            "Content-Type": "application/json"
        }
        
        print(f"Calling Cloud Function: {FUNCTION_URL}")
        response = requests.post(FUNCTION_URL, headers=headers, json={})
        response.raise_for_status()
        
        result = response.json()
        print(f"Success: {result}")
        return result
        
    except Exception as e:
        print(f"Error: {str(e)}")
        raise


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
        exists_ok=True
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
        exists_ok=True
    )

    # Task to write data to BigQuery
    upsert_data = BigQueryInsertJobOperator(
        task_id="upsert_air_pollution_to_bigquery",
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
    download_data >> create_staging_table >> etl_data >> create_fact_table >> upsert_data
```

So, here is the flow of the tasks being executed and automated:

*   Scraping data from Kaggle via Python code, executed via Cloud Function + Store the scraped data into Google Cloud Storage
*   Create the `staging.air_pollution_data` table to hold PySpark-transformed data from Dataproc, enabling upserts into fact.air_pollution_data via BigQuery's MERGE statement to prevent duplicate record insertion.
*   Perform ETL processing via Pyspark in DataProc, and then load the clean data into `staging.air_pollution_data` table in BigQuery
*   Create the `fact.air_pollution_data` table which serves as a data warehouse for our dataset 
*   Upsert the data from staging table in BigQuery to `fact.air_pollution_data` table in BigQuery

![](/images/composer-graph.png)


The DAG code is displayed in Airflow UI as well:

![](/images/composer-code.png)

*   Upload DAG to Composer bucket:

```bash
> gsutil cp dags/preprocess_aqi_dag.py gs://${DAGS_BUCKET}/dags/preprocess_aqi_dag.py
```

Step 7: Verify Deployment
-------------------------

*   Check if DAG file is properly uploaded to Composer's GCS bucket:

```bash
> gsutil cat gs://${DAGS_BUCKET}/dags/preprocess_aqi_dag.py
```

![](/images/composer-check-dags.png)

DAG Details
-----------

The DAG performs the following operations:

1.  Triggers Cloud Function to download data from Kaggle
2.  Create `staging.air_pollution_data` table only if not exists
3.  Submits PySpark job to Dataproc for data processing
4.  Create `fact.air_pollution_data` table only if not exists
5.  Loads processed data into BigQuery using MERGE operation for upsert operation which avoid duplicated entries being appended multiple times in BigQuery