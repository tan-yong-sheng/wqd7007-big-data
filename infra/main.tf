terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 4.50.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# Dynamically fetch the project number
data "google_project" "current_project" {
  project_id = var.project_id
  depends_on = [google_project_service.cloud_build_api] # Ensure API is enabled before trying to get project details
}

# modules
module "bigquery_dataset" {
  source = "./bigquery/dataset"
  project_id = var.project_id
  location = var.location
}
