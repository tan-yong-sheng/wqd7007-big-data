# Part 2b - Data processing with BigQuery SQL in BigQuery

## Upserting Data from Staging to Fact Table to Avoid Duplicates

> Before you continue to this guide, you should have BigQuery table setup in your Google Cloud account. If you haven't set it up yet. Please refer to our guide on [Part 3 - Analytics Layer: Set up BigQuery](./part3-analytics-layer.md), and then jump back to this guide.

BigQuery, a columnar analytics database, does not enforce constraints like unique keys, which means it allows inserting duplicate records. 

To prevent duplicates during the data insertion process, the `MERGE` statement can be used to upsert data from the `staging.air_pollution_data` table into the `fact.air_pollution_data` table, ensuring data consistency.

![](/images/bigquery-upsert-fact-table-sql.png)

```SQL
-- upsert data from staging.air_pollution_data table to fact.air_pollution_data table, to avoid duplicates during insertion task
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
```

#### Query Breakdown

1. **MERGE Operation**: The MERGE statement performs an "upsert" operation, combining both UPDATE and INSERT actions in a single query. This allows the system to either update existing records or insert new ones from the staging table into the `fact.air_pollution_data`, effectively preventing duplicate entries during data insertion.

2. **Matching Condition**: The query identifies existing records by matching on two key columns: country and city. These serve as the composite key to determine whether an air pollution record already exists in the target table. If both the country and city match between the staging and fact tables, the system considers it an existing record.

3. **When Matched (Update)**: If a record with the same country and city combination already exists in the fact.air_pollution_data table, the query updates all the air quality metrics with the latest values from the staging table. This includes updating AQI values and categories for overall air quality as well as specific pollutants (CO, ozone, NO2, PM2.5) and the dominant pollutant information.

4. **When Not Matched (Insert)**: If no matching record is found for a particular country-city combination, the query inserts a completely new row into the fact table. This new record includes all the air pollution data points: the overall AQI metrics, individual pollutant measurements and categories, and the dominant pollutant identifier from the staging table.

#### Benefits

*   **Prevents Duplicates**: Ensures that data is not duplicated when performing an insertion.
*   **Maintains Data Integrity**: Updates existing records with the latest information while adding new data where necessary.
