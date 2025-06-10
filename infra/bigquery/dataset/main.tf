# --- BigQuery ---


## 1. Activate necessary APIs

resource "google_project_service" "bigquery_api" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

## 2. Create the dataset
## 2a. Create fact dataset

resource "google_bigquery_dataset" "fact_dataset" {
  dataset_id                  = "fact"
  friendly_name               = "fact"
  description                 = "Fact table"
  location                    = var.location

  lifecycle { prevent_destroy = true }
}

## 2b. Create staging dataset

resource "google_bigquery_dataset" "staging_dataset" {
  dataset_id                  = "staging"
  friendly_name               = "staging"
  description                 = "Staging table"
  location                    = var.location

  lifecycle { prevent_destroy = true }
}
