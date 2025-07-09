## Terraform Resource Overview: GCP Big Data

> Note: please read the intro guide first [here](./README.md) before looking into this terraform's resource configuration setup,


Using Terraform, this project provisions a comprehensive data lakehouse environment on Google Cloud Platform, with each major component managed in a modular and maintainable way. Below is an overview of each layer and where its setup can be found in the `infra/` folder:

### 1. API Services and Foundation (`infra/apis.tf`)
Essential Google Cloud APIs (BigQuery, Dataproc, Cloud Storage, Composer, Cloud Functions, Cloud Build, etc.) are enabled using `google_project_service` resources. This ensures all required services are available before provisioning dependent resources.

```terraform
# --- Google Cloud's API Activation ---

# Enable necessary Google Cloud APIs

resource "google_project_service" "artifactregistry_api" {
  project                    = var.project_id
  service                    = "artifactregistry.googleapis.com"
  disable_dependent_services = false
}

resource "google_project_service" "bigquery_api" {
  project            = var.project_id
  service            = "bigquery.googleapis.com"
  disable_on_destroy = false
}
```

### 2. Data Ingestion Layer with Cloud Functions (`infra/cloud_function.tf`)
Cloud Functions and Cloud Build APIs are enabled, and IAM permissions are set up for deploying serverless functions. The code also handles packaging and deploying Cloud Functions for data ingestion, with permissions for Cloud Build to automate deployments.

```terraform
# Create the Cloud Function (Gen2)
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
}
```

### 3. Data Lake Storage Layer (`infra/storage_bucket.tf`)
Multiple Google Cloud Storage buckets are created for:
- Raw data (`bucket`)
- Staging job dependencies (`staging_bucket`)
- Temporary processing data (`temp_bucket`)
- Airflow DAGs (`dags_bucket`)
Each bucket is configured with appropriate lifecycle and access settings.

```terraform
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
```

### 4. Data Processing Layer with Dataproc (`infra/dataproc.tf`)
A Dataproc cluster is provisioned with master and worker nodes, network configuration, and storage integration. IAM roles are assigned to allow the cluster to interact with storage and other services.

```terraform
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
  }
}
```

### 5. Orchestration Layer with Cloud Composer (`infra/composer.tf`)
A Cloud Composer environment is provisioned to orchestrate the data pipelines. This includes setting up the necessary IAM roles for the Composer service account to interact with other GCP services like Dataproc and Cloud Functions.

```terraform
# --- Cloud Composer Environment ---
resource "google_composer_environment" "composer_env" {
  project  = var.project_id
  name     = var.composer_env_name
  region   = var.region

  storage_config {
      bucket = google_storage_bucket.dags_bucket.name
  }

  config {
    software_config {
      image_version = "composer-3-airflow-2.9.3"
      env_variables = {
        MY_PROJECT_ID       = var.project_id
        REGION              = var.region
        ZONE                = var.zone
        DATAPROC_CLUSTER_NAME = var.dataproc_cluster_name
        BUCKET              = var.bucket
        TEMP_BUCKET      = var.temp_bucket
        DAGS_BUCKET         = google_storage_bucket.dags_bucket.name
      }
    }
    environment_size = "ENVIRONMENT_SIZE_SMALL"

    node_config {
      service_account = "${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
    }
  }
}
```

### 6. Data Warehouse Layer with BigQuery (`infra/bigquery/dataset/main.tf`)
This module creates the necessary BigQuery datasets for staging and fact tables. Note that table schemas are managed outside of Terraform to allow for more flexible schema evolution.

```terraform
# --- BigQuery ---

## 2a. Create fact dataset
resource "google_bigquery_dataset" "fact_dataset" {
  dataset_id                  = "fact"
  friendly_name               = "fact"
  description                 = "Fact table"
  location                    = var.location

  lifecycle { 
    prevent_destroy = true
    ignore_changes = [access, labels]
  }
}

## 2b. Create staging dataset
resource "google_bigquery_dataset" "staging_dataset" {
  dataset_id                  = "staging"
  friendly_name               = "staging"
  description                 = "Staging table"
  location                    = var.location

  lifecycle { 
    prevent_destroy = true
    ignore_changes = [access, labels]
  }
}
```

Each section above corresponds to a specific `.tf` file or module in the `infra/` directory. For implementation details, refer to the respective files. This modular structure makes it easy to maintain, extend, or audit each part of your GCP data lakehouse infrastructure.