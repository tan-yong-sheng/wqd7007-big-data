locals {
  kaggle_json = jsonencode({
    username = var.kaggle_username
    key      = var.kaggle_key
  })
}

resource "google_secret_manager_secret" "kaggle_credentials" {
  secret_id = "kaggle-json"
  
  replication {
    auto {}
  }
}

# Grant access to service account
resource "google_project_iam_member" "secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]
}