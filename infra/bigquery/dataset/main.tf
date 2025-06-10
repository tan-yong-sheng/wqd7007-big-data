# --- BigQuery ---

# Note: We are intentionally avoiding Terraform for BigQuery schema creation and management
# due to the inherent difficulties it poses for future schema migrations and evolving data models.

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
