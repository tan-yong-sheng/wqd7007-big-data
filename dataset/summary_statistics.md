
# Summary statistics of the dataset, queried with BigQuery


1. Get the count of distinct countries

```sql
SELECT COUNT(DISTINCT country) AS total_countries
FROM fact.air_pollution_data;
```

![](/images/bigquery-country_count.png)


2. Ge the count of distinct cities

```sql
SELECT COUNT(DISTINCT city) AS total_cities
FROM fact.air_pollution_data;
```

![](/images/bigquery-city_count.png)


3. Get minimum and maximum AQI value

```sql
SELECT MIN(aqi_value) AS min_aqi,
       MAX(aqi_value) AS max_aqi
FROM fact.air_pollution_data;
```

![](/images/bigquery-get-min-max-aqi-value.png)


4. Get distribution of aqi categories in different cities

```sql
SELECT aqi_category,
       COUNT(*) AS num_cities
FROM fact.air_pollution_data
GROUP BY aqi_category
ORDER BY num_cities DESC;
```

![](/images/bigquery-num-cities-by-aqi-category.png)


5. Get average CO AQI value 

```sql
SELECT AVG(co_aqi_value) AS avg_co_aqi
FROM fact.air_pollution_data;
```

![](/images/bigquery-get_avg_co_aqi_value.png)

6. Get count of CO AQI category

```sql
SELECT co_aqi_category,
       COUNT(*) AS count
FROM fact.air_pollution_data
GROUP BY co_aqi_category;
```

![](/images/bigquery-aqi-category-count.png)


7. Get the average NO2 AQI value 
```sql
SELECT AVG(no2_aqi_value) AS avg_no2_aqi
FROM fact.air_pollution_data;
```
![](/images/bigquery-avg_no2_aqi_value.png)

8. Get the count of NO2 AQI category

```sql 
SELECT no2_aqi_category,
       COUNT(*) AS count
FROM fact.air_pollution_data
GROUP BY no2_aqi_category;
```

![](/images/bigquery-count_no2_aqi_category.png)

9. Get the average PM2.5 AQI category

```sql
SELECT AVG("pm2.5_aqi_value") AS avg_pm25_aqi
FROM fact.air_pollution_data;
```

![](/images/bigquery-avg_pm25_aqi_value.png)

10. Get the count of PM2.5 AQI category

```sql
SELECT "pm2.5_aqi_category",
       COUNT(*) AS count
FROM fact.air_pollution_data
GROUP BY "pm2.5_aqi_category"
ORDER BY count DESC;
```

![](/images/bigquery-count_pm25_aqi_category.png)



11. Get the min, average, and max of aqi value for each pollutants

```sql
SELECT 'CO' AS pollutant, MIN(co_aqi_value) AS min_aqi, AVG(co_aqi_value) AS avg_aqi, MAX(co_aqi_value) AS max_aqi
FROM fact.air_pollution_data

UNION ALL

SELECT 'NO2' AS pollutant, MIN(no2_aqi_value) AS min_aqi, AVG(no2_aqi_value) AS avg_aqi, MAX(no2_aqi_value) AS max_aqi
FROM fact.air_pollution_data

UNION ALL

SELECT 'PM2.5' AS pollutant, MIN(pm25_aqi_value) AS min_aqi, AVG(pm25_aqi_value) AS avg_aqi, MAX(pm25_aqi_value) AS max_aqi
FROM fact.air_pollution_data;
```

![](/images/bigquery-pivot-pollutants-distribution.png)


12. Get AQI category counts for the pollutants CO, NO₂, and PM2.5 

```sql
SELECT 
  'CO' AS pollutant,
  COUNTIF(co_aqi_category = 'Good') AS good_count,
  COUNTIF(co_aqi_category = 'Moderate') AS moderate_count,
  COUNTIF(co_aqi_category = 'Unhealthy for Sensitive Groups') AS sensitive_count,
  COUNTIF(co_aqi_category = 'Unhealthy') AS unhealthy_count,
  COUNTIF(co_aqi_category = 'Very Unhealthy') AS very_unhealthy_count,
  COUNTIF(co_aqi_category = 'Hazardous') AS hazardous_count
FROM fact.air_pollution_data

UNION ALL

SELECT 
  'NO2' AS pollutant,
  COUNTIF(no2_aqi_category = 'Good') AS good_count,
  COUNTIF(no2_aqi_category = 'Moderate') AS moderate_count,
  COUNTIF(no2_aqi_category = 'Unhealthy for Sensitive Groups') AS sensitive_count,
  COUNTIF(no2_aqi_category = 'Unhealthy') AS unhealthy_count,
  COUNTIF(no2_aqi_category = 'Very Unhealthy') AS very_unhealthy_count,
  COUNTIF(no2_aqi_category = 'Hazardous') AS hazardous_count
FROM fact.air_pollution_data

UNION ALL

SELECT 
  'PM2.5' AS pollutant,
  COUNTIF(`pm25_aqi_category` = 'Good') AS good_count,
  COUNTIF(`pm25_aqi_category` = 'Moderate') AS moderate_count,
  COUNTIF(`pm25_aqi_category` = 'Unhealthy for Sensitive Groups') AS sensitive_count,
  COUNTIF(`pm25_aqi_category` = 'Unhealthy') AS unhealthy_count,
  COUNTIF(`pm25_aqi_category` = 'Very Unhealthy') AS very_unhealthy_count,
  COUNTIF(`pm25_aqi_category` = 'Hazardous') AS hazardous_count
FROM fact.air_pollution_data;
```

![](/images/bigquery-aqi-category-counts-for-all-pollutants.png)