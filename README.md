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

- Need to setup `GOOGLE_CREDENTIALS_JSON` at GITHUB secrets for github workflows