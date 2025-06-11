## Data Description

Air pollution poses a significant threat to global public health, representing contamination of indoor and outdoor environments by chemical, physical, or biological agents that alter the natural characteristics of the atmosphere. Major pollution sources include household combustion devices, motor vehicles, industrial facilities, and forest fires, all contributing to elevated levels of harmful pollutants.

This dataset provides comprehensive geolocated information about key air quality indicators across global cities, focusing on pollutants of major public health concern. The data enables monitoring and analysis of air quality patterns worldwide, supporting research into respiratory diseases, environmental health impacts, and pollution control strategies.

The dataset contains Air Quality Index (AQI) measurements for multiple pollutants known to cause significant health effects, including respiratory diseases, cardiovascular problems, and increased mortality rates. Children, elderly populations, and individuals with pre-existing conditions like asthma face elevated risks from exposure to these pollutants.

'global air pollution dataset.csv' contains the comprehensive air quality data with AQI values and categories for each measured pollutant across different cities and countries worldwide.

The data comes from Kaggle: https://www.kaggle.com/datasets/hasibalmuzdadid/global-air-pollution-dataset/data

This data contains 12 columns with city-level air quality measurements for multiple pollutants.

## Data Dictionary

| **Column header**              | **Label**                           | **Description**                                                                                       |
|--------------------------------|-------------------------------------|-------------------------------------------------------------------------------------------------------|
| Country                        | **Country**                         | Name of the country where measurements were taken.                                                   |
| City                           | **City**                            | Name of the city where air quality was measured.                                                     |
| AQI Value                      | **Overall AQI Value**               | Composite Air Quality Index value representing overall air quality for the city.                     |
| AQI Category                   | **Overall AQI Category**            | Classification category for overall air quality (Good, Moderate, Unhealthy, etc.).                  |
| CO AQI Value                   | **Carbon Monoxide AQI Value**       | Air Quality Index value specifically for Carbon Monoxide concentration.                              |
| CO AQI Category                | **Carbon Monoxide AQI Category**    | Classification category for Carbon Monoxide levels (colorless, odorless gas from fossil fuel combustion). |
| Ozone AQI Value               | **Ozone AQI Value**                 | Air Quality Index value for ground-level Ozone concentration.                                        |
| Ozone AQI Category            | **Ozone AQI Category**              | Classification category for Ozone levels (formed by reactions between nitrogen oxides and volatile organic compounds). |
| NO2 AQI Value                 | **Nitrogen Dioxide AQI Value**      | Air Quality Index value for Nitrogen Dioxide concentration.                                          |
| NO2 AQI Category              | **Nitrogen Dioxide AQI Category**   | Classification category for Nitrogen Dioxide levels (primarily from vehicle emissions and power plants). |
| PM2.5 AQI Value               | **PM2.5 AQI Value**                 | Air Quality Index value for Particulate Matter with diameter ≤2.5 micrometers.                      |
| PM2.5 AQI Category            | **PM2.5 AQI Category**              | Classification category for PM2.5 levels (fine particles classified as Group 1 carcinogen by IARC). |

## Data Transformation Plan

We will perform a few data processing via pyspark in Dataproc as follows:
- Remove duplicated rows
- Remove rows with missing values for 'Country' and 'City' columns'
- Create a new column named dominant_pollutant, which contains the name of the pollutant (e.g., PM2.5, PM10, NO2, etc.) that has the highest AQI value in each row.