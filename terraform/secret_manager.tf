/*
Create a Secret Manager secret for the OpenAQ API key and grant access
to the Kestra and Cloud Run service accounts used in this project.
Controlled by var.create_openaq_secret. The actual secret value is only
added if var.openaq_api_key is provided (useful for CI / deploy-time).
*/

resource "google_secret_manager_secret" "openaq" {
  count     = var.create_openaq_secret ? 1 : 0
  secret_id = var.openaq_secret_name

  replication {
    auto {}
  }
}

# Optionally create a secret version from the provided value
resource "google_secret_manager_secret_version" "openaq_version" {
  count       = var.create_openaq_secret && var.openaq_api_key != "" ? 1 : 0
  secret      = google_secret_manager_secret.openaq[0].id
  secret_data = var.openaq_api_key
}

# Grant Kestra SA access to read the secret
resource "google_secret_manager_secret_iam_member" "kestra_accessor" {
  count     = var.create_openaq_secret ? 1 : 0
  secret_id = google_secret_manager_secret.openaq[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.kestra.email}"
}

# Grant Cloud Run service account access to read the secret
resource "google_secret_manager_secret_iam_member" "cloud_run_accessor" {
  count     = var.create_openaq_secret ? 1 : 0
  secret_id = google_secret_manager_secret.openaq[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.cloud_run_sa[0].email}"
}

# Grant Cloud Scheduler service account access (so scheduler can call with token if needed)
resource "google_secret_manager_secret_iam_member" "scheduler_accessor" {
  count     = var.create_openaq_secret ? 1 : 0
  secret_id = google_secret_manager_secret.openaq[0].id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}
