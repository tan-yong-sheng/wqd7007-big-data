# -- Google Cloud Storage's Bucket ---

resource "google_storage_bucket" "bucket" {
  project      = var.project_id
  name         = var.bucket
  location     = var.region
  force_destroy = false
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
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
