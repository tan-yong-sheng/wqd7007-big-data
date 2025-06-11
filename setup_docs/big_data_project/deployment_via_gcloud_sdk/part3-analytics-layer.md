# Part 3 - Analytics Layer: Set up BigQuery

## Setting Up BigQuery Tables for Global Air Pollution Data

This guide outlines the steps to create the necessary BigQuery datasets and tables for storing global air pollution data.


Step 1: Create Datasets
-----------------------

Create two datasets in BigQuery for staging and fact tables:

First, create the dataset in BigQuery. We've created two datasets in our BigQuery database, which are:-

(i) staging dataset:

```sql
CREATE SCHEMA IF NOT EXISTS staging
OPTIONS (
  location = "US"
);
```

![](/images/bigquery-create-staging-dataset.png)

(ii) fact dataset:

```sql
CREATE SCHEMA IF NOT EXISTS fact
OPTIONS (
  location = "US"
);
```

![](/images/bigquery-create-fact-dataset.png)


Step 2: Create Tables
---------------------

### Create Staging Table

*   The staging table will temporarily store the processed data before moving it to the fact table:

```sql
CREATE TABLE IF NOT EXISTS staging.air_pollution_data(
  country STRING NOT NULL,
  city STRING NOT NULL,
  aqi_value INT64,
  aqi_category STRING,
  co_aqi_value INT64,
  co_aqi_category STRING,
  ozone_aqi_value INT64, 
  ozone_aqi_category STRING,
  no2_aqi_value FLOAT64,
  no2_aqi_category STRING,
  pm25_aqi_value INT64,
  pm25_aqi_category STRING,
  dominant_pollutant STRING
);
```
![](/images/bigquery-create-staging-table.png)


### Create Fact Table

*   The fact table will store the final, clean data:

```sql
CREATE TABLE IF NOT EXISTS fact.air_pollution_data(
  country STRING NOT NULL,
  city STRING NOT NULL,
  aqi_value INT64,
  aqi_category STRING,
  co_aqi_value INT64,
  co_aqi_category STRING,
  ozone_aqi_value INT64, 
  ozone_aqi_category STRING,
  no2_aqi_value FLOAT64,
  no2_aqi_category STRING,
  pm25_aqi_value INT64,
  pm25_aqi_category STRING,
  dominant_pollutant STRING
);
```

![](/images/bigquery-create-fact-table.png)


Table Details
-------------

Both tables share identical schema with the following columns:

- `country`
- `city`
- `aqi_value`
- `aqi_category`
- `co_aqi_value`
- `co_aqi_category`
- `ozone_aqi_value` 
- `ozone_aqi_category`
- `no2_aqi_value`
- `no2_aqi_category`
- `pm25_aqi_value`
- `pm25_aqi_category`
- `dominant_pollutant`

Data Flow
---------

1.  Processed data from Dataproc is first loaded into the `staging.air_pollution_data` table
2.  Data is then merged into the `fact.air_pollution_data` table using the upsert operation, automated and orchestrated by Google Cloud Composer
3.  The `staging.air_pollution_data` table is used as a temporary landing zone to hold PySpark-transformed data from Dataproc, enabling upserts into `fact.air_pollution_data` table via BigQuery's MERGE statement to prevent duplicate record insertion.

