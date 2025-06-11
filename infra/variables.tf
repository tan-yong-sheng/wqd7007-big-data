variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "The GCP region for the resources."
  type        = string
}

variable "location" {
  description = "The GCP's location for the resources, either 'US' or 'EU'"
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

variable "dags_bucket" {
  description = "The name of the staging bucket."
  type        = string
}

variable "bucket" {
  description = "The name of the primary bucket."
  type        = string
}

variable "staging_bucket" {
  description = "The name of the staging bucket to store job dependencies and config files of Dataproc cluster"
  type        = string
}

variable "temp_bucket" {
  description = "The name of the temp bucket to hold intermediate and temporary runtime data during Dataproc job execution"
  type        = string
}
