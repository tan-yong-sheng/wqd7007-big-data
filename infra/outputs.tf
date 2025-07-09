output "project_id" {
  description = "The GCP project ID"
  value       = var.project_id
}

output "region" {
  description = "The GCP region"
  value       = var.region
}

# Output the Cloud function URL
output "function_url" {
  description = "The URL of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.download_kaggle_data.service_config[0].uri
}

# --- GitHub Workload Identity outputs ---
output "workload_identity_provider" {
  description = "The full resource name of the workload identity provider for GitHub Actions"
  value       = google_iam_workload_identity_pool_provider.github_provider.name
}

output "github_actions_service_account_email" {
  description = "Email of the service account for GitHub Actions"
  value       = google_service_account.github_actions_sa.email
}

output "dags_bucket" {
  description = "The name of the DAGs bucket for GitHub Actions sync"
  value       = var.dags_bucket
}