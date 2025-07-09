# --- Cloud Function ---

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


# 3. Grant the Compute Engine default service account (used by the trigger) the Cloud Run Admin role
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


# Use the default Compute Engine service account
data "google_service_account" "existing_function_sa" {
  account_id = "${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  project    = var.project_id
}

# Create a ZIP file of your function source code
data "archive_file" "function_source" {
  type        = "zip"
  source_dir  = "${path.module}/../src/scripts/download_kaggle_data"
  output_path = "${path.module}/../tmp/download_kaggle_data.zip"
}

# Upload the function source ZIP to Google Cloud Storage
resource "google_storage_bucket_object" "function_source" {
  name   = "function-source-${data.archive_file.function_source.output_md5}.zip"
  bucket = var.bucket
  source = data.archive_file.function_source.output_path
  
  depends_on = [data.archive_file.function_source]
}


# 4. Create the Cloud Function (Gen2)
resource "google_cloudfunctions2_function" "download_kaggle_data" {
  name        = "download_kaggle_data"
  location    = var.region
  project     = var.project_id
  description = "Download Kaggle data function"

  build_config {
    runtime     = "python310"
    entry_point = "main"  # Make sure this matches your function entry point
    
    source {
      storage_source {
        bucket = google_storage_bucket_object.function_source.bucket
        object = google_storage_bucket_object.function_source.name
      }
    }
  }

  service_config {
    max_instance_count = 10
    min_instance_count = 0
    available_memory   = "1024Mi"
    timeout_seconds    = 540
    
    environment_variables = {
      PROJECT_ID = var.project_id
      BUCKET     = var.bucket
    }
    
    secret_environment_variables {
      key        = var.secret_id
      project_id = var.project_id
      secret     = var.secret_id
      version    = "latest"
    }
    
    ingress_settings = "ALLOW_ALL"
    
    # Use existing service account for the function
    service_account_email = data.google_service_account.existing_function_sa.email
  }

  depends_on = [
    data.google_project.current_project,
    google_project_service.cloud_functions_api,
    google_project_service.cloud_build_api,
    google_project_service.cloud_run_api,
    google_secret_manager_secret_version.kaggle_credentials_version,
  ]
}

# Grant necessary permissions to the existing service account
resource "google_project_iam_member" "function_sa_permissions" {
  for_each = toset([
    "roles/storage.objectAdmin",
    "roles/secretmanager.secretAccessor",
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter",
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
  depends_on = [
    data.google_project.current_project
  ]

}

# Make the function publicly accessible (equivalent to --allow-unauthenticated)
resource "google_cloudfunctions2_function_iam_member" "public_access" {
  project        = var.project_id
  location       = var.region
  cloud_function = google_cloudfunctions2_function.download_kaggle_data.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
