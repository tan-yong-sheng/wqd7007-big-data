# WQD7007 Big Data Project

- Note: need to solve how to deploy secrets automatically via cloud build or github workflows

Test for Step 1 in terminal:
- curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <CLOUD_FUNCTION_URL>

- terraform gcp secrets https://medium.com/google-cloud/terraform-on-google-cloud-v1-3-secret-manager-and-its-what-why-and-how-c4f56adb0c92

Cloud build for Composer
- https://medium.com/@amarachi.ogu/implementing-ci-cd-in-cloud-composer-using-cloud-build-and-github-part-2-a721e4ed53da

Using composer to automate dataproc cluster creation
- https://freedium.cfd/https://medium.com/google-cloud/use-composer-for-dataproc-serverless-workloads-27ccf9561539; https://cloud.google.com/composer/docs/composer-2/run-dataproc-workloads; https://airflow.apache.org/docs/apache-airflow-providers-google/stable/operators/cloud/dataproc.html#create-a-batch

- interesting yet hard to set up: https://medium.com/google-cloud/setting-up-a-datamesh-using-dataplex-and-cloud-composer-5742d30918b0

- Terraform with cloud build: https://blog.devops.dev/terraform-using-google-cloud-build-a-very-basic-example-723f5fb58bca

- Terraform for BigQuery https://github.com/sudovazid/gcp_terraform/tree/main

```
gcloud secrets create kaggle-json --data-file=kaggle.json
```

```
export PROJECT_ID=gp-461213
export REGION=us-central1
export BUCKET=air-pollution-data-my
export STAGING_BUCKET=staging-air-pollution-data-my
export TEMP_BUCKET=temp-air-pollution-data-my
export DATAPROC_CLUSTER_NAME=air-qualiterty-cluster
export SERVICE_ACCOUNT_EMAIL=1000028997311-compute@developer.gserviceaccount.com
```


```
gcloud dataproc clusters create air-quality-cluster \
  --region=us-central1 \
  --single-node \
  --bucket=staging-air-pollution-data-my \
  --temp-bucket=temp-air-pollution-data-my
```


```
export GCP_PROJECT_ID="gp-461213"
export GCP_REGION="us-central1"
export DATAPROC_CLUSTER_NAME="air-quality-cluster"
export STAGING_BUCKET_NAME="staging-air-pollution-data-my"
export TEMP_BUCKET_NAME="temp-air-pollution-data-my"
export SERVICE_ACCOUNT="1000028997311-compute@developer.gserviceaccount.com"

gcloud dataproc clusters create "${DATAPROC_CLUSTER_NAME}" \
    --project="${GCP_PROJECT_ID}" \
    --region="${GCP_REGION}" \
    --network="default" \
    --service-account=${SERVICE_ACCOUNT} \
    --scopes="https://www.googleapis.com/auth/cloud-platform" \
    --master-machine-type="n1-standard-2" \
    --master-boot-disk-type="pd-standard" \
    --master-boot-disk-size="30" \
    --num-workers="2" \
    --worker-machine-type="n1-standard-2" \
    --worker-boot-disk-type="pd-ssd" \
    --worker-boot-disk-size="30" \
    --image-version="2.1-debian11" \
    --bucket="${STAGING_BUCKET_NAME}" \
    --temp-bucket="${TEMP_BUCKET_NAME}" \
    --labels="environment=dev,created_by=gcloud-script,purpose=etl-pipeline" \
    --max-idle="30m" \
    --enable-component-gateway \
    --no-address

```