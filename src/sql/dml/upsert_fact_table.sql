MERGE INTO fact.global_air_pollution AS target
USING staging.global_air_pollution AS source
ON target.country = source.country 
   AND target.city = source.city 
   AND target.aqi_value = source.aqi_value
   AND target.aqi_category = source.aqi_category
   AND target.co_aqi_value = source.co_aqi_value
   AND target.co_aqi_category = source.co_aqi_category
   AND target.ozone_aqi_value = source.ozone_aqi_value
   AND target.ozone_aqi_category = source.ozone_aqi_category
   AND target.no2_aqi_value = source.no2_aqi_value
   AND target.no2_aqi_category = source.no2_aqi_category
   AND target.pm25_aqi_value = source.pm25_aqi_value
   AND target.pm25_aqi_category = source.pm25_aqi_category
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
      pm25_aqi_category = source.pm25_aqi_category
WHEN NOT MATCHED THEN
INSERT (country, city, aqi_value, aqi_category, co_aqi_value, co_aqi_category, ozone_aqi_value, ozone_aqi_category, no2_aqi_value, no2_aqi_category,  pm25_aqi_value, pm25_aqi_category)
VALUES (source.country, source.city, source.aqi_value, source.aqi_category, source.co_aqi_value, source.co_aqi_category, source.ozone_aqi_value, source.ozone_aqi_category, source.no2_aqi_value, source.no2_aqi_category, source.pm25_aqi_value, source.pm25_aqi_category);