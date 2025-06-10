# --- Setup settings for Cloud Composer Environment ---

# 1. Create a dedicated Service Account for the Composer environment
resource "google_service_account" "composer_service_account" {
  project      = var.project_id
  account_id   = "composer-sa-${var.composer_env_name}" # Unique ID for the SA
  display_name = "Service account for Composer environment ${var.composer_env_name}"
}

# 2. Grant necessary IAM roles to the Service Account
resource "google_project_iam_member" "composer_worker_role" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${google_service_account.composer_service_account.email}"
}

resource "google_project_iam_member" "storage_object_admin_role" {
  project = var.project_id
  role    = "roles/storage.objectAdmin" # Or more specific like objectViewer if appropriate
  member  = "serviceAccount:${google_service_account.composer_service_account.email}"
}

# Grant the SA permissions on the DAGs bucket (critical for Composer)
resource "google_storage_bucket_iam_member" "dags_bucket_iam" {
  bucket = google_storage_bucket.dags_bucket.name
  role   = "roles/storage.objectAdmin" # Composer needs to read/write DAGs, logs, plugins
  member = "serviceAccount:${google_service_account.composer_service_account.email}"
}

# DAGS bucket
resource "google_storage_bucket" "dags_bucket" {
  name          = var.dags_bucket
  project       = var.project_id
  location      = var.region
  force_destroy = false
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}

# --- Cloud Composer Environment ---
resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = var.composer_env_name
  region   = var.region

  depends_on = [
    google_project_service.composer_api,
    google_project_iam_member.composer_worker_role, # Ensure roles are granted before Composer creation
    google_project_iam_member.storage_object_admin_role,
    google_storage_bucket_iam_member.dags_bucket_iam # Ensure bucket IAM is set
  ]

  storage_config {
      bucket = google_storage_bucket.dags_bucket.name
  }

  config {
    software_config {
      image_version = "composer-3-airflow-2.9.3"
      env_variables = {
        MY_PROJECT_ID       = var.project_id
        REGION              = var.region
        ZONE                = var.zone
        DATAPROC_CLUSTER_NAME = var.dataproc_cluster_name
        BUCKET              = var.bucket
        STAGING_BUCKET      = var.staging_bucket
        DAGS_BUCKET         = google_storage_bucket.dags_bucket.name
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = google_service_account.composer_service_account.email
    }
  }
}