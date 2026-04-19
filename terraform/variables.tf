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

# Optional GKE / Workload Identity configuration
variable "create_gke_cluster" {
  description = "Whether to create a GKE cluster for Kestra (optional)."
  type        = bool
  default     = false
}

variable "gke_cluster_name" {
  description = "Name of the GKE cluster (if created)."
  type        = string
  default     = "kestra-cluster"
}

variable "gke_node_count" {
  description = "Initial node count for the GKE cluster."
  type        = number
  default     = 1
}

variable "gke_machine_type" {
  description = "Machine type for GKE nodes."
  type        = string
  default     = "e2-medium"
}

variable "k8s_namespace" {
  description = "Kubernetes namespace where Kestra will run (for Workload Identity binding)."
  type        = string
  default     = "kestra"
}

variable "k8s_service_account" {
  description = "Kubernetes service account name to bind to the GCP Kestra SA."
  type        = string
  default     = "kestra-sa"
}

# Cloud Run + Scheduler (low-cost orchestration path)
variable "create_cloud_run" {
  description = "Whether to create Cloud Run service and Scheduler job."
  type        = bool
  default     = false
}

variable "cloud_run_service_name" {
  description = "Cloud Run service name for ingestion"
  type        = string
  default     = "openaq-ingest"
}

variable "cloud_run_image" {
  description = "Container image for the Cloud Run service (e.g. gcr.io/project/image:tag)"
  type        = string
  default     = "gcr.io/data-engineering-zoomcamp2026/openaq-ingest:latest"
}

variable "cloud_run_region" {
  description = "GCP region for Cloud Run service"
  type        = string
  default     = "us-east1"
}

variable "scheduler_cron" {
  description = "Cron schedule for Cloud Scheduler job"
  type        = string
  default     = "0 * * * *"
}

# Secret Manager for OpenAQ API key
variable "create_openaq_secret" {
  description = "Whether to create a Secret Manager secret for the OpenAQ API key"
  type        = bool
  default     = false
}

variable "openaq_secret_name" {
  description = "Secret name to store the OpenAQ API key"
  type        = string
  default     = "openaq-api-key"
}

variable "openaq_api_key" {
  description = "(Optional) OpenAQ API key value to populate as a secret version. Leave empty to create secret without version."
  type        = string
  default     = ""
  sensitive   = true
}

# Optional Kestra VM (small Compute Engine instance) for hosting Kestra UI via Docker Compose
variable "create_kestra_vm" {
  description = "Whether to create a small Compute Engine VM to host Kestra (optional, low-cost demo)."
  type        = bool
  default     = false
}

variable "kestra_vm_name" {
  description = "Name for the Kestra VM instance"
  type        = string
  default     = "kestra-vm"
}

variable "kestra_vm_zone" {
  description = "Zone for the Kestra VM"
  type        = string
  default     = "us-east1-b"
}

variable "kestra_vm_machine_type" {
  description = "Machine type for the Kestra VM"
  type        = string
  default     = "e2-small"
}

variable "kestra_repo_url" {
  description = "Optional git repo URL to clone on the VM (if empty, VM will not auto-clone)."
  type        = string
  default     = ""
}

