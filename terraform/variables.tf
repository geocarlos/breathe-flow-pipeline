variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "data-engineering-zoomcamp2026"
}

variable "region" {
  description = "Region for GCP resources"
  type        = string
  default     = "us-east1" # Adjust if you prefer a different region
}

variable "location" {
  description = "Project Location"
  type        = string
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  type        = string
  default     = "breathe-flow-pipeline"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  type        = string
  default     = "breathe-flow-pipeline-storage"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  type        = string
  default     = "STANDARD"
}