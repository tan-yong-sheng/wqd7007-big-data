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

# --- API Activation ---
resource "google_project_service" "composer_api" {
  project                    = var.project_id
  service                    = "composer.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "container_api" {
  project                    = var.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "artifactregistry_api" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = false
}

# --- Cloud Storage Bucket for DAGs ---
resource "google_storage_bucket" "dags_bucket" {
  project      = var.project_id
  name         = "${var.region}-airflow-bucket"
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}

# --- Cloud Composer Environment ---
resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = var.composer_env_name
  region   = var.region

  depends_on = [google_project_service.composer_api]

  config {
    software_config {
      image_version = "composer-3-airflow-2.9.3"
      env_variables = {
        MY_PROJECT_ID  = var.project_id
        REGION         = var.region
        ZONE           = var.zone
        DATAPROC_CLUSTER_NAME = var.dataproc_cluster_name
        BUCKET         = var.bucket
        STAGING_BUCKET = var.staging_bucket
        DAGS_BUCKET    = google_storage_bucket.dags_bucket.name
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"
    storage_config {
      bucket = google_storage_bucket.dags_bucket.name
    }
  }
}