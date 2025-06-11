
# Configure Network Settings
    # Enable Private Google Access for the default subnet.
    # WARNING: Directly modifying the 'default' subnet using `google_compute_subnetwork`
    # can be brittle as Terraform will attempt to manage its entire state.
    # The `lifecycle { ignore_changes = [...] }` block is used here to tell Terraform
    # to only manage 'private_ip_google_access' and ignore all other properties
    # of the default subnet that might be managed externally or by GCP itself.
    # For production environments, it is highly recommended to create a custom VPC network
    # and subnets with Private Google Access enabled from the outset, rather than
    # modifying the default network.

resource "google_compute_subnetwork" "default_subnet_private_access_update" {
  # Referencing the default subnet by its name and region
  name    = "default"
  project = var.project_id
  region  = var.region

  # The default subnet is part of the 'default' VPC network.
  network = "default" 

  # Set private_ip_google_access to true, as specified in your script.
  private_ip_google_access = true

  # Ignore changes to other properties of the default subnet to prevent unintended drift
  # or recreation if those properties are managed externally.
  lifecycle {
    ignore_changes = [
      ip_cidr_range,
      network,
      secondary_ip_range,
      stack_type,
      role,
      purpose,
      private_ipv6_google_access,
    ]
  }

  # Ensure relevant APIs are enabled before attempting to modify network settings.
  depends_on = [
    google_project_service.storage_api,
    google_project_service.bigquery_api,
    google_project_service.dataproc_api
  ]
}