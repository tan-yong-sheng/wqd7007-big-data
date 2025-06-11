## Terraform Resource Overview: GCP Big Data

> Note: please read the intro guide first [here](./README.md) before looking into this terraform's resource configuration setup,

Using Terraform, we could automatically provisions a comprehensive data lakehouse environment on Google Cloud Platform with several key resource layers that align with modern data architecture patterns.


1. **API Services and Foundation**: The setup begins by enabling essential Google Cloud APIs across all required services including BigQuery, Dataproc, Cloud Storage, Composer, Cloud Functions, and Cloud Build. These API activations form the foundation for all subsequent resource creation:

```
terraform resource "google_project_service" "bigquery_api" {
  project = var.project_id
  service = "bigquery.googleapis.com"
  disable_on_destroy = false
}
```

```
resource "google_project_service" "cloud_functions_api" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
  disable_on_destroy = false
}
```

2. **Data Ingestion Layer with Cloud Functions**: The infrastructure enables Cloud Functions API and establishes the necessary IAM permissions for deploying serverless functions that handle data ingestion workflows. This includes setting up Cloud Build capabilities to automatically deploy and manage these functions as part of the CI/CD pipeline.

3. **Data Lake Storage Layer**: Multiple Cloud Storage buckets are strategically created for different purposes - a primary data lake bucket for raw data storage, a staging bucket for job dependencies and configuration files, a temporary bucket for runtime processing data, and a dedicated DAGs bucket for Airflow workflows:

```
terraform resource "google_storage_bucket" "bucket" {
  project      = var.project_id
  name         = var.bucket
  location     = var.region
  force_destroy = false
  uniform_bucket_level_access = true
  lifecycle {
    prevent_destroy = true
  }
}
```

```
resource "google_storage_bucket" "staging_bucket" {
  project      = var.project_id
  name         = var.staging_bucket
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}
```

```
resource "google_storage_bucket" "temp_bucket" {
  project      = var.project_id
  name         = var.temp_bucket
  location     = var.region
  force_destroy = true
  uniform_bucket_level_access = true
}
```

4. **Data Processing Layer with Dataproc**: A fully configured Dataproc cluster is provisioned for big data processing with both master and worker nodes. The cluster includes proper network configuration, storage integration, and service account permissions:

```
terraform resource "google_dataproc_cluster" "dataproc_cluster" {
  name    = var.dataproc_cluster_name
  region  = var.region
  cluster_config {
    staging_bucket = google_storage_bucket.staging_bucket.name
    temp_bucket    = google_storage_bucket.temp_bucket.name
    master_config {
      num_instances = 1
      machine_type  = "n1-standard-2"
      disk_config {
        boot_disk_type    = "pd-standard"
        boot_disk_size_gb = 30
      }
    }
    worker_config {
      num_instances = 2
      machine_type  = "n1-standard-2"
    }
  }
}
```

5. **Analytics and Data Warehousing Layer**: BigQuery datasets are automatically created for both fact tables (production data) and staging tables (intermediate processing)

```
terraformresource "google_bigquery_dataset" "fact_dataset" {
  dataset_id    = "fact"
  friendly_name = "fact"
  description   = "Fact table"
  location      = var.location
  lifecycle { 
    prevent_destroy = true
    ignore_changes = [access, labels]
  }
}
```

```
resource "google_bigquery_dataset" "staging_dataset" {
  dataset_id    = "staging"
  friendly_name = "staging"
  description   = "Staging table"
  location      = var.location
}
```

6. **Orchestration Layer with Cloud Composer**: A complete Cloud Composer (Apache Airflow) environment is established for workflow orchestration, including its dedicated storage bucket and all necessary environment variables for seamless integration with other pipeline components:

```
terraform resource "google_composer_environment" "composer_env" {
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
        MY_PROJECT_ID         = var.project_id
        DATAPROC_CLUSTER_NAME = var.dataproc_cluster_name
        BUCKET                = var.bucket
      }
    }
    node_config {
      service_account = "${data.google_project.current_project.number}-compute@developer.gserviceaccount.com"
    }
  }
}
```


7. **Network Security and Configuration**: The infrastructure modifies the default VPC subnet to enable Private Google Access, ensuring that resources without external IP addresses can securely reach Google APIs and services, which is essential for the Dataproc cluster's operation and overall security posture:

```
terraform resource "google_compute_subnetwork" "default_subnet_private_access_update" {
  name    = "default"
  project = var.project_id
  region  = var.region
  network = "default"
  private_ip_google_access = true
}
```

8. **Comprehensive IAM and Security Management**: The setup includes extensive IAM role assignments across all services, ensuring that the default Compute Engine service account has appropriate permissions for storage administration, Dataproc operations, Composer workflows, and cross-service communication. This includes project-wide storage admin permissions and specific role bindings for each service component to maintain security while enabling seamless data flow throughout the pipeline.