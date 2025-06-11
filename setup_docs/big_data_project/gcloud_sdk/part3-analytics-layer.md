# Part 3 - Analytics Layer: Set up BigQuery
### Setting Up BigQuery Tables for CO2 Emissions Data

This guide outlines the steps to create the necessary BigQuery datasets and tables for storing CO2 emissions data.


Step 1: Create Datasets
-----------------------

Create two datasets in BigQuery for staging and fact tables:

First, create the dataset in BigQuery. We've created two datasets in our BigQuery database, which are:-

(i) staging dataset:

![](../images/bigquery-create-staging-table-schema.png)

```sql
CREATE SCHEMA IF NOT EXISTS staging
OPTIONS (
  location = "US"
);
```

(ii) fact dataset:

![](../images/bigquery-create-fact-table-schema.png)

```sql
CREATE SCHEMA IF NOT EXISTS fact
OPTIONS (
  location = "US"
);
```

You could also create them manually via the UI:

![](../images/3_Part%203%20-%20Analytics%20Layer%20Set%20u.jpg)

Step 2: Create Tables
---------------------

### Create Staging Table

*   The staging table will temporarily store the processed data before moving it to the fact table:

![](../images/2_Part%203%20-%20Analytics%20Layer%20Set%20u.jpg)

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

### Create Fact Table

*   The fact table will store the final, clean data:

![](../images/Part%203%20-%20Analytics%20Layer%20Set%20u.jpg)

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

1.  Processed data from Dataproc is first loaded into the staging table
2.  Data is then merged into the fact table using the upsert operation, automated and orchestrated by Google Cloud Composer
3.  The staging table is used as a temporary landing zone to ensure data quality before final loading to avoid data duplication during data insertion, as BigQuery doesn't enforce unique key validation
