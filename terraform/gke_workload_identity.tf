/*
Optional GKE cluster creation and Workload Identity binding.
Set `create_gke_cluster = true` to create a simple cluster
and enable Workload Identity. The real value of this file is
the Workload Identity IAM binding which allows a Kubernetes
service account to impersonate the Kestra GCP service account.
*/

locals {
  workload_pool = "${var.project_id}.svc.id.goog"
}

resource "google_container_cluster" "kestra_cluster" {
  count               = var.create_gke_cluster ? 1 : 0
  name                = var.gke_cluster_name
  location            = var.region
  initial_node_count  = var.gke_node_count

  node_config {
    machine_type = var.gke_machine_type
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  remove_default_node_pool = false
}

# Bind the Kestra GCP service account to the Kubernetes service account via Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  service_account_id = google_service_account.kestra.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${local.workload_pool}[${var.k8s_namespace}/${var.k8s_service_account}]"
}

output "gke_workload_pool" {
  description = "The workload identity pool for the project (useful for KSA annotations)."
  value       = local.workload_pool
}
