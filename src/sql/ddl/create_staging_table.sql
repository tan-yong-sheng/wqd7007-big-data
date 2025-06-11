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
