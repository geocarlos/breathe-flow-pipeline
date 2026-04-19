/*
Optional Cloud Run service + Cloud Scheduler job to run the ingestion container.
Controlled by var.create_cloud_run (default: false).
*/

resource "google_service_account" "cloud_run_sa" {
  count       = var.create_cloud_run ? 1 : 0
  account_id  = "cloud-run-ingest-sa"
  display_name = "Cloud Run Ingest Service Account"
}

resource "google_service_account" "scheduler_sa" {
  count       = var.create_cloud_run ? 1 : 0
  account_id  = "cloud-scheduler-sa"
  display_name = "Cloud Scheduler Service Account"
}

resource "google_cloud_run_service" "ingest_service" {
  count     = var.create_cloud_run ? 1 : 0
  name      = var.cloud_run_service_name
  location  = var.cloud_run_region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa[0].email
      containers {
        image = var.cloud_run_image
      }
    }
  }

  autogenerate_revision_name = true
}

# Allow the scheduler SA to invoke the Cloud Run service
resource "google_cloud_run_service_iam_member" "invoker" {
  count   = var.create_cloud_run ? 1 : 0
  location = google_cloud_run_service.ingest_service[0].location
  project  = var.project_id
  service  = google_cloud_run_service.ingest_service[0].name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${google_service_account.scheduler_sa[0].email}"
}

# Cloud Scheduler job to POST to Cloud Run using OAuth token
resource "google_cloud_scheduler_job" "ingest_job" {
  count    = var.create_cloud_run ? 1 : 0
  name     = "openaq-ingest-scheduler"
  project  = var.project_id
  region   = var.cloud_run_region

  http_target {
    uri = "${google_cloud_run_service.ingest_service[0].status[0].url}"
    http_method = "POST"

    oidc_token {
      service_account_email = google_service_account.scheduler_sa[0].email
      audience = google_cloud_run_service.ingest_service[0].status[0].url
    }
  }

  schedule = var.scheduler_cron
  time_zone = "UTC"
}

output "cloud_run_url" {
  description = "Cloud Run service URL (if created)"
  value = try(google_cloud_run_service.ingest_service[0].status[0].url, "")
}
