CREATE TABLE IF NOT EXISTS fact.global_air_pollution(
  country STRING NOT NULL,
  city STRING NOT NULL,
  aqi_value INT64 NULL, 
  aqi_category STRING NULL, 
  co_aqi_value INT64 NULL,
  co_aqi_category STRING NULL,
  ozone_aqi_value INT64 NULL, 
  ozone_aqi_category STRING NULL,
  no2_aqi_value FLOAT64 NULL,
  no2_aqi_category STRING NULL,
  pm25_aqi_value INT64 NULL,
  pm25_aqi_category STRING NULL
  dominant_pollutant STRING NULL
);
