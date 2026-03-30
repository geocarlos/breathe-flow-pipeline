terraform {
  required_version = ">= 1.0"
  backend "local" {}  # Can be upgraded to "gcs" later
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}