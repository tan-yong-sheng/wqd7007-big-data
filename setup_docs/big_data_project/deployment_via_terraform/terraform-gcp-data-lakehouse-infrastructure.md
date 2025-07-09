## Terraform Resource Overview: GCP Big Data

> Note: please read the intro guide first [here](./README.md) before looking into this terraform's resource configuration setup,


Using Terraform, this project provisions a comprehensive data lakehouse environment on Google Cloud Platform, with each major component managed in a modular and maintainable way. Below is an overview of each layer and where its setup can be found in the `infra/` folder:

### 1. API Services and Foundation (`infra/apis.tf`)
Essential Google Cloud APIs (BigQuery, Dataproc, Cloud Storage, Composer, Cloud Functions, Cloud Build, etc.) are enabled using `google_project_service` resources. This ensures all required services are available before provisioning dependent resources.

### 2. Data Ingestion Layer with Cloud Functions (`infra/cloud_function.tf`)
Cloud Functions and Cloud Build APIs are enabled, and IAM permissions are set up for deploying serverless functions. The code also handles packaging and deploying Cloud Functions for data ingestion, with permissions for Cloud Build to automate deployments.

### 3. Data Lake Storage Layer (`infra/storage_bucket.tf`, `infra/dataproc.tf`)
Multiple Google Cloud Storage buckets are created for:
- Raw data (`bucket`)
- Staging job dependencies (`staging_bucket`)
- Temporary processing data (`temp_bucket`)
- Airflow DAGs (`dags_bucket`)
Each bucket is configured with appropriate lifecycle and access settings.

### 4. Data Processing Layer with Dataproc (`infra/dataproc.tf`)
A Dataproc cluster is provisioned with master and worker nodes, network configuration, and storage integration. IAM roles are assigned to allow the cluster to interact with storage and other services.

### 5. Analytics and Data Warehousing Layer (`infra/bigquery/dataset/main.tf`)
BigQuery datasets for both fact and staging tables are created. The setup avoids managing table schemas directly in Terraform for flexibility in future schema changes.

### 6. Orchestration Layer with Cloud Composer (`infra/composer.tf`)
A Cloud Composer (Airflow) environment is provisioned, including its storage bucket and all necessary environment variables. IAM roles are assigned to allow Composer to orchestrate Dataproc, Cloud Functions, and storage.

### 7. Network Security and Configuration (`infra/subnetworks.tf`)
The default VPC subnet is updated to enable Private Google Access, allowing resources without external IPs to securely access Google APIs. The configuration uses `lifecycle { ignore_changes = [...] }` to avoid conflicts with GCP-managed properties.

### 8. Comprehensive IAM and Security Management (`infra/composer.tf`, `infra/dataproc.tf`, `infra/cloud_function.tf`, `infra/secrets.tf`)
IAM roles are assigned across all services to ensure secure and seamless data flow. This includes storage admin, Dataproc editor, Composer worker, Cloud Functions invoker, and secret accessor roles for service accounts.

### 9. Secrets Management (`infra/secrets.tf`)
Google Secret Manager is enabled and used to securely store and manage sensitive credentials (e.g., Kaggle API keys), with access granted to the necessary service accounts.

### 10. GitHub Actions Workload Identity Federation (`infra/github_workload_identity.tf`)
Workload Identity Federation is set up to allow GitHub Actions to deploy infrastructure and sync DAGs securely to GCP using OIDC, without storing long-lived credentials.

---

Each section above corresponds to a specific `.tf` file or module in the `infra/` directory. For implementation details, refer to the respective files. This modular structure makes it easy to maintain, extend, or audit each part of your GCP data lakehouse infrastructure.