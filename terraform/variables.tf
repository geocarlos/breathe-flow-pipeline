variable "project_id" {
  description = "Your GCP Project ID"
  type        = string
}

variable "region" {
  description = "Region for GCP resources"
  default     = "us-central1"
}

variable "storage_class" {
  description = "Storage class type for your bucket"
  default     = "STANDARD"
}

variable "gcs_bucket_name" {
  description = "Globally unique name for your Data Lake bucket"
  type        = string
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset name where dbt will work"
  default     = "ecommerce_data_all"
}