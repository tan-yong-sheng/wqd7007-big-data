# --- GitHub Actions Workload Identity Federation ---

# 1. Create Workload Identity Pool for GitHub Actions
resource "google_iam_workload_identity_pool" "github_pool" {
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions Pool"
  description               = "Identity pool for GitHub Actions workflows"
  disabled                  = false

  depends_on = [google_project_service.iam_api]
}

# 2. Create Workload Identity Pool Provider for GitHub
resource "google_iam_workload_identity_pool_provider" "github_provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github_pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"

  display_name = "GitHub Actions Provider"
  description  = "OIDC provider for GitHub Actions"
  
  # Map GitHub token claims to Google Cloud attributes
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
  }

  # Condition to restrict access to your specific repository
  attribute_condition = "assertion.repository == '${var.github_username}/${var.github_repo}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }

  depends_on = [google_iam_workload_identity_pool.github_pool]
}

# 3. Create Service Account for GitHub Actions
resource "google_service_account" "github_actions_sa" {
  account_id   = "github-actions-sa"
  display_name = "GitHub Actions Service Account"
  description  = "Service account for GitHub Actions workflows"
}

# 4. Allow the GitHub Actions to impersonate the service account
resource "google_service_account_iam_binding" "github_actions_workload_identity_binding" {
  service_account_id = google_service_account.github_actions_sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github_pool.name}/attribute.repository/${var.github_username}/${var.github_repo}"
  ]

  depends_on = [
    google_iam_workload_identity_pool_provider.github_provider,
    google_service_account.github_actions_sa
  ]
}

# 5. Grant permissions to the GitHub Actions service account
resource "google_project_iam_member" "github_actions_permissions" {
  for_each = toset([
    "roles/storage.admin",           # For syncing files to GCS buckets
    "roles/iam.serviceAccountUser",  # For Terraform to use service accounts
    "roles/editor",                  # For Terraform to manage resources (can be more restrictive)
  ])
  
  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.github_actions_sa.email}"
  
  depends_on = [google_service_account.github_actions_sa]
} 