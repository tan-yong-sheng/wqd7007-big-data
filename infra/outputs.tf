output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

# Output the Cloud function URL
output "function_url" {
  description = "URL of the deployed Cloud Function"
  value       = google_cloudfunctions2_function.download_kaggle_data.service_config[0].uri
}