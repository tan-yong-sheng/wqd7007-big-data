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

# --- Create Google cloud storage bucket to save data ----
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

# -- Setup of permission of Cloud Build for deploying Cloud Run function
# 1. Activate cloud build API
resource "google_project_service" "cloud_build_api" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

# 3. Grant the Cloud Run Admin role to the Cloud Build service account
#    This service account is automatically created and managed by Google Cloud
#    when cloudbuild.googleapis.com is enabled. You don't create it with google_service_account.
resource "google_project_iam_member" "cloud_build_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.current_project.number}@cloudbuild.gserviceaccount.com" # Corrected to Cloud Build SA
  depends_on = [google_project_service.cloud_build_api] # Ensure API is enabled before granting role
}

# 4. Grant the Cloud Build service account permission to act as the Cloud Function's runtime service account
# This is often necessary for deploying Gen2 functions where the runtime SA is different from the builder SA.
# The runtime SA for your function is 1000028997311-compute@developer.gserviceaccount.com
resource "google_service_account_iam_member" "cloud_build_act_as_runtime_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/1000028997311-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_project.current_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.iam_api, # Ensure IAM API is enabled
    data.google_project.current_project
  ]
}
