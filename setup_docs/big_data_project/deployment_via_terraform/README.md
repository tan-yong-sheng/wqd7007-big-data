# Intro Guide for Automated Deployment of Big Data Infrastructure via Terraform

Terraform is an infrastructure-as-code (IaC) tool that enables automated provisioning and management of cloud resources. This guide walks you through deploying a complete big data infrastructure stack to Google Cloud Platform.

> After reading this guide, please refer to the [Terraform Resource Configuration documentation](terraform-gcp-data-lakehouse-infrastructure.md) to understand which big data infrastructure components are automatically provisioned via Terraform.

1. Authenticate with Google Cloud

Run the following commands to authenticate:

```
gcloud auth login
gcloud auth default-application login
```

- `gcloud auth login`: Authenticates your user account for use with the Google Cloud CLI.
- `gcloud auth application-default login`: Sets up credentials for Application Default Credentials (used by Terraform and client libraries).

2. Configure Terraform Variables

Navigate to the infrastructure directory:

```bash
cd infra
```

Rename the example configuration file to create your active configuration:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit the `terraform.tfvars` file and fill in your Kaggle credentials. You can obtain these credentials by downloading the `kaggle.json` API key file from your Kaggle account settings page:  [https://www.kaggle.com/settings](https://www.kaggle.com/settings).

Extract the username and key values from your `kaggle.json` file and add them to the `kaggle_username` and `kaggle_key` variables in `terraform.tfvars`. Also, remember to change the project_id as well.


![](/images/terraform-setup-variable.png)

3. **Validate Configuration**

Validate your Terraform configuration to ensure there are no syntax errors:

```bash
terraform validate
```

![](/images/terraform-validate.png)


4. **Preview Changes**

Generate an execution plan to preview the infrastructure changes Terraform will make. This allows you to review all resources that will be created, modified, or destroyed:

```bash
terraform plan
```

![](/images/terraform-plan1.png)

![](/images/terraform-plan2.png)

5. **Deploy Infrastructure**

Apply the changes to deploy your big data infrastructure. Terraform will prompt for confirmation before making any changes to your cloud resources:

```bash
terraform apply
```

![](/images/terraform-apply1.png)


![](/images/terraform-apply2.png)

The deployment process will show real-time progress as Terraform creates your infrastructure resources. Once completed, you'll see a summary of the resources that were successfully created.

