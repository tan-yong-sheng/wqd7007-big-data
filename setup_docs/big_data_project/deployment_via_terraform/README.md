# Guide to Deploy Big Data Infrastructure to GCP via Terraform

Terraform is an infrastructure-as-code (IaC) tool that enables automated provisioning and management of cloud resources. This guide walks you through deploying a complete big data infrastructure stack to Google Cloud Platform.

> Please refer to the [documentation](./README.md) to understand which big data infrastructure components are automatically provisioned via Terraform.

## Deployment Steps

1. **Validate Configuration**

Navigate to the infrastructure directory and validate your Terraform configuration to ensure there are no syntax errors:

```
cd infra
terraform validate
```

![](/images/terraform-validate.png)


2. **Preview Changes**

Generate an execution plan to preview the infrastructure changes Terraform will make. This allows you to review all resources that will be created, modified, or destroyed:

```
terraform plan
```

![](/images/terraform-plan1.png)

![](/images/terraform-plan2.png)

3. **Deploy Infrastructure**

Apply the changes to deploy your big data infrastructure. Terraform will prompt for confirmation before making any changes to your cloud resources:

```
terraform apply
```

![](/images/terraform-apply1.png)


![](/images/terraform-apply2.png)

The deployment process will show real-time progress as Terraform creates your infrastructure resources. Once completed, you'll see a summary of the resources that were successfully created.

