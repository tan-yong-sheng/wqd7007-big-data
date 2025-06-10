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

resource "google_storage_bucket" "staging_bucket" {
  project      = var.project_id
  name         = var.staging_bucket
  location     = var.region
  force_destroy = false
  uniform_bucket_level_access = true

  lifecycle {
    prevent_destroy = true
  }
}
