# 1. Define kaggle secret variables

locals {
  kaggle_json = jsonencode({
    username = var.kaggle_username
    key      = var.kaggle_key
  })
}

# 2. Enable google secret manager api
resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
}

# 3. Grant access of google secret manager service to service account
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]
}

# 4. Create Kaggle secrets in google secret manager
resource "google_secret_manager_secret" "kaggle_credentials" {
  secret_id = var.secret_id
  
  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager_api,
    google_project_service.cloudresourcemanager_api
  ]
}

# 5. Create the secret version with the Kaggle credentials data
resource "google_secret_manager_secret_version" "kaggle_credentials_version" {
  secret      = google_secret_manager_secret.kaggle_credentials.id
  secret_data = local.kaggle_json

  depends_on = [
    google_secret_manager_secret.kaggle_credentials,
    google_project_service.secretmanager_api,
    google_project_service.cloudresourcemanager_api
  ]
}
