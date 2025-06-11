# Part 2a - Data Processing Layer : Set up Dataproc for ETL task

## Setting Up Dataproc for Data Processing Pipeline

This guide outlines the steps to set up a Dataproc cluster and run PySpark jobs to process data from Google Cloud Storage to BigQuery.

Prerequisites
-------------

*   Google Cloud Platform account with billing enabled
*   Google Cloud Shell or local environment with gcloud CLI installed
*   Required IAM permissions

Step 1: Configure Environment Variables
---------------------------------------

The commands are executed under the cloud shell terminal…

![](/images/cloud-shell.png)

Set up the necessary environment variables in Cloud Shell:

```bash
export PROJECT_ID="gp-461213"
export REGION="us-central1"
export BUCKET="air-pollution-data-my"
export STAGING_BUCKET="staging-air-pollution-data-my"
export TEMP_BUCKET="temp-air-pollution-data-my"
export DATAPROC_CLUSTER_NAME="air-quality-cluster"
export SERVICE_ACCOUNT_EMAIL="1000028997311-compute@developer.gserviceaccount.com"
```

Step 2: Enable Required APIs
----------------------------

Enable the necessary Google Cloud APIs:

```bash
gcloud services enable \
  storage.googleapis.com \
  bigquery.googleapis.com \
  dataproc.googleapis.com
```

Step 3: Configure Network Settings
----------------------------------

*   Enable private Google Access for the default subnet:

```bash
# Enable private IP Google access
gcloud compute networks subnets update default \
 --region=${REGION} \
 --enable-private-ip-google-access
```

```bash
# Verify the configuration
gcloud compute networks subnets describe default \
 --region=${REGION} \
 --format="get(privateIpGoogleAccess)"
```

Step 4: Set Up Storage
----------------------

*   Create GCS buckets:

```bash
# Create main data bucket
gsutil mb -l ${REGION} gs://${BUCKET}

# Create staging bucket
gsutil mb -l ${REGION} gs://${STAGING_BUCKET}

# Create staging bucket
gsutil mb -l ${REGION} gs://${TEMP_BUCKET}
```

Create necessary folder structure:

*   Create a `dataset` folder for your data
*   Create a `staging` folder to store job dependencies and config files of Dataproc cluster
*   Create a `temp` folder hold intermediate and temporary runtime data during Dataproc job execution

Step 5: Configure IAM Permissions
---------------------------------

Grant storage admin permissions to the service account:

```bash
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member=serviceAccount:${SERVICE_ACCOUNT_EMAIL} \
    --role="roles/storage.admin"
```



Step 6: Create Dataproc Cluster
----------------------------------

Create a single-node Dataproc cluster with component gateway enabled:

```bash
gcloud dataproc clusters create ${DATAPROC_CLUSTER_NAME} \
  --region=${REGION} \
  --single-node \
  --bucket=${BUCKET} \
  --temp-bucket=${TEMP_BUCKET} \
  --enable-component-gateway
```

Output here:

![](/images/1_Part%202%20-%20Data%20Processing%20Layer.jpg)



Step 7: GCS to BigQuery Data Pipeline
-------------------------------------

*   Create the data processing script `src/scripts/preprocess_aqi_data/main.py`:
    *   Implements data loading from GCS
    *   Includes schema definition
    *   Handles data deduplication
    *   Feature engineering to create a new feature called `dominant_pollutant`
    *   Overwrite the data to BigQuery's staging table

```bash
nano src/scripts/preprocess_aqi_data/main.py
```

Add the following Python Code for the Dataproc's script:

```python
import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, greatest, when
from pyspark.sql.types import StructType, StructField, StringType, IntegerType

def create_spark_session():
    # Create Spark session with the necessary configurations
    spark = SparkSession.builder \
        .appName("GCS_to_BigQuery") \
        .getOrCreate()
    return spark


def preprocess_aqi_data(spark, gcs_path):
    """
    Function to load data from a GCS bucket to BigQuery.
    Parameters:
        spark: Spark session object.
        gcs_path: GCS path to the input dataset (e.g., gs://bucket/dataset.csv).
    """

    # Define the schema explicitly to ensure correct data types
    schema = StructType([
        StructField("country", StringType(), True),
        StructField("city", StringType(), True),
        StructField("aqi_value", IntegerType(), True),
        StructField("aqi_category", StringType(), True),
        StructField("co_aqi_value",  IntegerType(), True),
        StructField("co_aqi_category", StringType(), True),
        StructField("ozone_aqi_value", IntegerType(), True),
        StructField("ozone_aqi_category", StringType(), True),
        StructField("no2_aqi_value", IntegerType(), True),
        StructField("no2_aqi_category", StringType(), True),
        StructField("pm25_aqi_value", IntegerType(), True),
        StructField("pm25_aqi_category", StringType(), True),
    ])

    # Read the dataset from GCS with the predefined schema
    df = spark.read.option("header", "true").schema(schema).csv(gcs_path)
    print(f"Read data from GCS: {gcs_path}")

    # De-duplicate the data based on all rows
    df = df.distinct()
    print("De-duplicated the dataset based on all columns.")

    # Remove rows with missing values for 'Country' and 'City' columns
    df = df.dropna(subset=["Country", "City"])
    print("Removed rows with missing values for 'Country' and 'City' columns.")

    # Add new feature, called `dominant_pollutant`
    ## First, compute the maximum AQI value across pollutants
    df = df.withColumn("max_aqi", greatest(
        col("pm25_aqi_value"), 
        col("no2_aqi_value"), 
        col("ozone_aqi_value"), 
        col("co_aqi_value")
    ))
    # Then assign the pollutant that matches the max value
    df = df.withColumn("dominant_pollutant", 
        when(col("pm25_aqi_value") == col("max_aqi"), "PM2.5")
        .when(col("no2_aqi_value") == col("max_aqi"), "NO2")
        .when(col("ozone_aqi_value") == col("max_aqi"), "Ozone")
        .otherwise("CO")
    )
    # Drop the helper column as it is not needed
    df = df.drop("max_aqi")

    return df


def load_data_to_bigquery(spark_df, bigquery_table, bucket_name):
    """
    Function to load data from a GCS bucket to BigQuery.
    Parameters:
        spark_df: spark dataframe
        bigquery_table: Destination BigQuery table (e.g., `project.dataset.table_name`).
        bucket_name: Temporary GCS bucket for BigQuery load jobs.
    """  
    # Write the DataFrame to BigQuery
    spark_df.write \
        .format("bigquery") \
        .option("table", bigquery_table) \
        .option("temporaryGcsBucket", bucket_name) \
        .mode("overwrite") \
        .save()

    print(f"Data written to BigQuery table: {bigquery_table}")


def main():
    # Set up argument parsing
    parser = argparse.ArgumentParser(description="Load data from GCS to BigQuery using PySpark.")
    parser.add_argument("--gcs_path", required=True, help="GCS path to the input dataset (e.g., gs://bucket/dataset.csv).")
    parser.add_argument("--bigquery_table", required=True, help="Destination BigQuery table (e.g., project.dataset.table).")
    parser.add_argument("--bucket_name", required=True, help="Temporary GCS bucket for BigQuery load jobs.")

    args = parser.parse_args()

    # Create Spark session
    spark = create_spark_session()
    # preprocess aqi_data with pyspark
    spark_df = preprocess_aqi_data(spark, args.gcs_path)
    # Load data from GCS to BigQuery
    _ = load_data_to_bigquery(spark_df, args.bigquery_table, args.bucket_name)


if __name__ == "__main__":
    main()
```

*   Submit the data processing job in Cloud Shell:

```bash
gcloud dataproc jobs submit pyspark src/scripts/preprocess_aqi_data/main.py \
   --cluster=${DATAPROC_CLUSTER_NAME} \
   --region=${REGION} \
   -- \
   --gcs_path=gs://${BUCKET}/dataset/global-air-pollution-datasets.csv \
   --bigquery_table=${PROJECT_ID}.fact.air_pollution_data \
   --bucket_name=${STAGING_BUCKET}
```

![](/images/dataproc-submit-jobs-via-gcloud-sdk.png
)

And here is the UI where you could monitor the Dataproc's Job:

![](/images/dataproc-monitoring-ui.png)

Script Features
---------------

The GCS to BigQuery script includes:

*   Data deduplication
*   Handling missing values
*   Feature Engineering (i.e., create a new variable)