# --- Setup settings for Cloud Composer Environment ---

# 1. Grant necessary IAM roles to the Service Account
resource "google_project_iam_member" "composer_worker_role" {
  project = var.project_id
  role    = "roles/composer.worker"
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]
}

resource "google_project_iam_member" "storage_object_admin_role" {
  project = var.project_id
  role    = "roles/storage.objectAdmin" # Or more specific like objectViewer if appropriate
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]
}

# Grant the SA permissions on the DAGs bucket (critical for Composer)
resource "google_storage_bucket_iam_member" "dags_bucket_iam" {
  bucket = google_storage_bucket.dags_bucket.name
  role   = "roles/storage.objectAdmin" # Composer needs to read/write DAGs, logs, plugins
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]
}

# --- DAGS bucket ---
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
        TEMP_BUCKET      = var.temp_bucket
        DAGS_BUCKET         = google_storage_bucket.dags_bucket.name
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = "${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
    }
  }
}
