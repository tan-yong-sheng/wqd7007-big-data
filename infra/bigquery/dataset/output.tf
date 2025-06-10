output "fact_dataset_id" {
  description = "The ID of the fact dataset"
  value       = google_bigquery_dataset.fact_dataset.dataset_id
}

output "staging_dataset_id" {
  description = "The ID of the fact dataset"
  value       = google_bigquery_dataset.staging_dataset.dataset_id
}