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

# Kestra service account configuration
variable "kestra_sa_account_id" {
  description = "Service account account_id for Kestra"
  type        = string
  default     = "kestra-sa"
}

# Optionally create a long-lived service account key for local PoC (use with caution)
variable "create_kestra_sa_key" {
  description = "Whether to create a long-lived service account key for the Kestra SA (for local PoC only)."
  type        = bool
  default     = false
}
