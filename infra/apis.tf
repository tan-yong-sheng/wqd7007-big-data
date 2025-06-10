
# --- Google Cloud's API Activation ---

# Enable necessary Google Cloud APIs

resource "google_project_service" "artifactregistry_api" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "bigquery_api" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "container_api" {
  project                    = var.project_id
  service                    = "container.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "cloud_functions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false # Set to true to disable API on 'terraform destroy'
}


# might need these common APIs for various GCP operations
resource "google_project_service" "cloudresourcemanager_api" {
  project = var.project_id
  service = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "composer_api" {
  project                    = var.project_id
  service                    = "composer.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "compute_api" {
  project = var.project_id
  service = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dataplex_api" {
  project = var.project_id
  service = "dataplex.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "dataproc_api" {
  project = var.project_id
  service = "dataproc.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "logging_api" {
  project = var.project_id
  service = "logging.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "monitoring_api" {
  project = var.project_id
  service = "monitoring.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "serviceusage_api" {
  project = var.project_id
  service = "serviceusage.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "storage_api" {
  project = var.project_id
  service = "storage.googleapis.com"
  disable_on_destroy = false
}
