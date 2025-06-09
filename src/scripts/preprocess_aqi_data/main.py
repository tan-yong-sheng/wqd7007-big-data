import argparse

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, greatest, when
from pyspark.sql.types import StructType, StructField, StringType, FloatType

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
        StructField("aqi_value", StringType(), True),
        StructField("aqi_category", StringType(), True),
        StructField("co_aqi_value",  StringType(), True),
        StructField("co_aqi_category", StringType(), True),
        StructField("ozone_aqi_value", StringType(), True),
        StructField("ozone_aqi_category", StringType(), True),
        StructField("no2_aqi_value", StringType(), True),
        StructField("no2_aqi_category", StringType(), True),
        StructField("pm25_aqi_value", StringType(), True),
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

