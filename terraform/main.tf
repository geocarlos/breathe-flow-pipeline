# Data Lake (GCS Bucket)
resource "google_storage_bucket" "data-lake-bucket" {
  name                        = var.gcs_bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 30 # Days
    }
  }

  force_destroy = true
}

# Data Warehouse (BigQuery Dataset)
resource "google_bigquery_dataset" "dataset" {
  dataset_id = var.bq_dataset_name
  project    = var.project_id
  location   = var.region

  description = "Dataset for the E-Commerce Zoomcamp Project"
}

# External Table: Bridges GCS JSON files to BigQuery
resource "google_bigquery_table" "external_openaq_raw" {
  dataset_id          = google_bigquery_dataset.dataset.dataset_id
  table_id            = "raw_air_quality"
  deletion_protection = false

  external_data_configuration {
    autodetect    = true
    source_format = "NEWLINE_DELIMITED_JSON"
    source_uris   = ["gs://${google_storage_bucket.data-lake-bucket.name}/raw/*.json"]
  }
}
