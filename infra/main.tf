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

# --- Cloud Storage Bucket for DAGs ---
resource "google_storage_bucket" "dags_bucket" {
  project      = var.project_id
  name         = "${var.region}-airflow-bucket"
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "bucket" {
  project      = var.project_id
  name         = "air-pollution-data-my"
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_storage_bucket" "staging_bucket" {
  project      = var.project_id
  name         = "staging-air-pollution-data-my"
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}


# --- Cloud Composer Environment ---
# resource "google_composer_environment" "composer_env" {
#  project  = var.project_id
#  name     = var.composer_env_name
#  region   = var.region

#  depends_on = [google_project_service.composer_api]

#  config {
#    software_config {
#      image_version = "composer-3-airflow-2.9.3"
#      env_variables = {
#        MY_PROJECT_ID  = var.project_id
#        REGION         = var.region
#        ZONE           = var.zone
#        DATAPROC_CLUSTER_NAME = var.dataproc_cluster_name
#        BUCKET         = var.bucket
#        STAGING_BUCKET = var.staging_bucket
#        DAGS_BUCKET    = google_storage_bucket.dags_bucket.name
#      }
#    }
#    environment_size = "ENVIRONMENT_SIZE_SMALL"
#    #storage_config {
#    #  bucket = google_storage_bucket.dags_bucket.name
#    #}
#  }