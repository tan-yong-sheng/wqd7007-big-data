# WQD7007 Big Data Project

- Note: need to solve how to deploy secrets automatically via cloud build or github workflows

Test for Step 1 in terminal:
- curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" <CLOUD_FUNCTION_URL>

Using composer to automate dataproc cluster creation
- https://freedium.cfd/https://medium.com/google-cloud/use-composer-for-dataproc-serverless-workloads-27ccf9561539; https://cloud.google.com/composer/docs/composer-2/run-dataproc-workloads; https://airflow.apache.org/docs/apache-airflow-providers-google/stable/operators/cloud/dataproc.html#create-a-batch

- interesting yet hard to set up: https://medium.com/google-cloud/setting-up-a-datamesh-using-dataplex-and-cloud-composer-5742d30918b0