variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the resources."
  type        = string
}

variable "zone" {
  description = "The GCP zone for the Dataproc PHS cluster."
  type        = string
}

variable "composer_env_name" {
  description = "The name of the Cloud Composer environment."
  type        = string
}

variable "dataproc_cluster_name" {
  description = "The name of the Dataproc PHS cluster."
  type        = string
}

variable "bucket" {
  description = "The name of the primary bucket."
  type        = string
}

variable "staging_bucket" {
  description = "The name of the staging bucket."
  type        = string
}