# --- Cloud Build ---
## Note: we're not automating the whole CI/CD deployment automation setup for Cloud Build, 
##       as some part of them are automated via the cloudbuild.yaml file already
##       Here, we just automate the permission setup for our Service account for 
##       running and administrating Cloud Build

# Setup of permission of Cloud Build for deploying Cloud Run function
# 1. Activate necessary APIs
## Ensure cloud build API is enabled (as a dependency for the below)

resource "google_project_service" "cloud_build_api" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
  disable_on_destroy = false
}

## 2. Ensure Cloud Run and Cloud Functions API is enabled (as a dependency for the below)

resource "google_project_service" "cloud_run_api" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "cloud_functions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false # Set to true to disable API on 'terraform destroy'
}

# 3. Grant the Cloud Build service account permission to act as the Cloud Function's runtime service account
# This is often necessary for deploying Gen2 functions where the runtime SA is different from the builder SA.
# The runtime SA for our function is 1000028997311-compute@developer.gserviceaccount.com

resource "google_service_account_iam_member" "cloud_build_act_as_runtime_sa" {
  service_account_id = "projects/${var.project_id}/serviceAccounts/${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${data.google_project.current_project.number}@cloudbuild.gserviceaccount.com"
  depends_on = [
    google_project_service.iam_api, # Ensure IAM API is enabled
    data.google_project.current_project
  ]
}

# 4. Grant the Compute Engine default service account (used by the trigger) the Cloud Run Admin role
# This is needed because the trigger is now configured to run as this service account.

resource "google_project_iam_member" "compute_sa_run_admin" {
  project = var.project_id
  role    = "roles/run.admin"
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    google_project_service.cloud_run_api, # Ensure Cloud Run API is enabled
    data.google_project.current_project
  ]
}