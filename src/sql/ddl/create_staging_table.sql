CREATE TABLE IF NOT EXISTS staging.global_air_pollution(
  country STRING NOT NULL,
  city STRING NOT NULL,
  aqi_value INT64 NOT NULL, 
  aqi_category STRING NOT NULL, 
  co_aqi_value INT64 NOT NULL,
  co_aqi_category STRING NOT NULL,
  ozone_aqi_value INT64 NOT NULL, 
  ozone_aqi_category STRING NOT NULL,
  no2_aqi_value FLOAT64 NOT NULL,
  no2_aqi_category STRING NOT NULL,
  pm25_aqi_value INT64 NOT NULL,
  pm25_aqi_category STRING NOT NULL
);