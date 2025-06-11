# -- Dataproc cluster setup --

# --- Step 1: Set Up Temporary Storage  ---

## Cloud storage to store job dependencies and config files
resource "google_storage_bucket" "staging_bucket" {
  project      = var.project_id
  name         = var.staging_bucket
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true
  
  depends_on = [google_project_service.storage_api]

  lifecycle {
    prevent_destroy = false
  }
}

## Cloud storage bucket to hold intermediate and temporary runtime data during Dataproc job execution
resource "google_storage_bucket" "temp_bucket" {
  project      = var.project_id
  name         = var.temp_bucket
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true
  
  depends_on = [google_project_service.storage_api]

  lifecycle {
    prevent_destroy = false
  }
}

# Grant 'roles/storage.admin' at the project level to the default Compute Engine service account.
# This permission allows the Dataproc cluster (running as this SA) to read/write to GCS buckets.
resource "google_project_iam_member" "storage_admin_binding" {
  project = var.project_id
  role    = "roles/storage.admin"
  member  = "serviceAccount:${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"

  depends_on = [
    data.google_project.current_project,
    google_project_service.storage_api]
}

# --- Step 3: Create Dataproc Cluster ---
# Create a single-node Dataproc cluster as specified in your script.
resource "google_dataproc_cluster" "dataproc_cluster" {
  name    = var.dataproc_cluster_name
  region  = var.region
  project = var.project_id

  # Labels are key-value pairs that help you organize and track resources.
  labels = {
    environment = "dev"
    created_by  = "terraform"
    purpose     = "etl-pipeline"
  }

  cluster_config {
    # Specify the main GCS bucket for Dataproc temporary and staging files.
    staging_bucket = google_storage_bucket.staging_bucket.name
    temp_bucket    = google_storage_bucket.temp_bucket.name

    gce_cluster_config {
      zone = null
      # Assign the default Compute Engine service account to cluster VM instances.
      service_account = "${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
      # Grant full Cloud Platform scope for the service account to access other GCP services.
      service_account_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
      # Use the default network and subnet for the cluster.
      subnetwork = "default"
    }

    # Configure the master node
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-2" # Example machine type, adjust as needed.
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 30 # Adjust disk size based on your job's needs.
      }
    }

    # IMPORTANT: Define worker_config with num_instances = 0 for a master-only cluster.
    worker_config {
      num_instances = 2 # Example: 2 worker nodes
      machine_type  = "n1-standard-2" # Machine type for workers
      disk_config {
        boot_disk_type    = "pd-ssd" # Example: Use SSD for better performance
        boot_disk_size_gb = 30       # Example: 50 GB boot disk for each worker
      }
    }

    # Configure the Dataproc software stack.
    software_config {
      # Use a stable Dataproc image version. Refer to GCP documentation for latest recommended versions.
      image_version = "2.1-debian11"
    }

    # Enable Component Gateway for easier access to Spark UI, Jupyter, etc.
    #component_gateway {
    #  enabled = false
    #}
  }

  timeouts {
    create = "30m"
    update = "20m"
    delete = "10m"
  }

  # Ensure all necessary APIs and buckets are ready before creating the cluster.
  depends_on = [
    google_compute_subnetwork.default_subnet_private_access_update,  # Explicitly depend on the subnetwork update to ensure Private Google Access is enabled.
    google_project_service.dataproc_api,
    google_storage_bucket.temp_bucket,
    google_project_iam_member.storage_admin_binding,
  ]
}
