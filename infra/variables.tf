## Variables that will prompt user to answer during terraform program's execution

variable "kaggle_username" {
  description = "Kaggle username"
  type        = string
  sensitive   = true
}

variable "kaggle_key" {
  description = "Kaggle API key"
  type        = string
  sensitive   = true
}

variable "secret_id" {
  description = "The name of the Kaggle secrets stored in Google Secret Manager"
  type        = string
}

## Variables that prompt user to answer during terraform program's execution (as answered in terraform.tfvars file)

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
  description = "The GCP zone for the Dataproc cluster."
  type        = string
}

variable "github_username" {
  description = "Your GitHub username"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$", var.github_username))
    error_message = "GitHub username must be valid."
  }
}

variable "github_repo" {
  description = "Your GitHub repository name"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]+$", var.github_repo))
    error_message = "GitHub repository name must be valid."
  }
}

variable "composer_env_name" {
  description = "The name of the Cloud Composer environment."
  type        = string
}

variable "dataproc_cluster_name" {
  description = "The name of the Dataproc cluster."
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
