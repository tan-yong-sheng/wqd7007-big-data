# Data LakeHouse Architecture Pipeline

> Important: please test if the gcloud secrets could be successfully deployed via terraform...

This project demonstrates the design and implementation of a basic Data LakeHouse Architecture Pipeline using Google Cloud Platform (GCP) services. The pipeline is structured into six key layers: Orchestration, Ingestion, Storage, Process, Analytics, and Visualization. Each layer plays a critical role in transforming raw data into actionable insights, ensuring scalability, reliability, and automation at every stage of the data workflow.

We would like to invite you to explore our documentation guide, which outlines the setup steps for creating a simple Data Lakehouse in Google Cloud. Our team utilized tools like Cloud Functions, Google Cloud Storage, Dataproc, BigQuery, and Looker Studio to build this streamlined solution.

Basically there are 2 ways for the deployment of this Big Data Infrastructure:

(a) Manually executing gcloud sdk on Google Cloud Shell to deploy each services one by one:

- [Part 1 - Data Ingestion Layer with Cloud Function](/setup_docs/big_data_project/deployment_via_gcloud_sdk/part1-data-ingestion-layer.md)
- [Part 2a - Data Processing Layer with Dataproc](/setup_docs/big_data_project/deployment_via_gcloud_sdk/part2a-data-processing-layer.md)
- [Part 2b - Data Processing Layer with BigQuery SQL in BigQuery](/setup_docs/big_data_project/deployment_via_gcloud_sdk/part2b-data-processing-layer.md)
- [Part 3 - Analytics Layer with BigQuery](/setup_docs/big_data_project/deployment_via_gcloud_sdk/part3-analytics-layer.md)
- [Part 4 - Orchestration Layer with Composer](/setup_docs/big_data_project/deployment_via_gcloud_sdk/part4-orchestration-layer.md)
- Part 5 - Data Governance Layer with Dataplex

(b) Automated deployment via Terraform script
- [Intro Guide](/setup_docs/big_data_project/deployment_via_terraform/README.md)
- [Terraform Resource Configuration](/setup_docs/big_data_project/deployment_via_terraform/terraform-gcp-data-lakehouse-infrastructure.md)

## Contribution

Thank you, team, for your hard work, support, and collaboration:

- Chow Kai Ern
- Karam
- Kevin Wong 
- Li Yuexin
- Mohammed Iqram
- Tan Yong Sheng