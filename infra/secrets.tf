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
  secret_id = "kaggle-json"
  
  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager_api,
    google_project_service.cloudresourcemanager_api,
  ]

  timeouts {
    create = "10m"
  }
}
