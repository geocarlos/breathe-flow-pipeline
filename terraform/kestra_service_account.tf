resource "google_service_account" "kestra" {
  account_id   = var.kestra_sa_account_id
  display_name = "Kestra service account"
}

# Grant the service account access to the GCS data lake bucket
resource "google_storage_bucket_iam_member" "kestra_bucket" {
  bucket = google_storage_bucket.data-lake-bucket.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.kestra.email}"
}

# Grant the service account access to the BigQuery dataset
resource "google_bigquery_dataset_iam_member" "kestra_dataset" {
  dataset_id = google_bigquery_dataset.dataset.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = "serviceAccount:${google_service_account.kestra.email}"
}

# Allow the service account to run BigQuery jobs in the project
resource "google_project_iam_member" "kestra_bq_job_user" {
  project = var.project_id
  role    = "roles/bigquery.jobUser"
  member  = "serviceAccount:${google_service_account.kestra.email}"
}

# Optional: Create a long-lived service account key (use with caution)
resource "google_service_account_key" "kestra_key" {
  count              = var.create_kestra_sa_key ? 1 : 0
  service_account_id = google_service_account.kestra.name
  private_key_type   = "TYPE_GOOGLE_CREDENTIALS_FILE"
}
