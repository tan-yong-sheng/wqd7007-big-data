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