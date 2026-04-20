/*
Optional VM to host Kestra for demos. Controlled by var.create_kestra_vm.
The instance runs with the existing `kestra` service account created elsewhere
in the Terraform config so it inherits the IAM roles you assigned to that SA.

Note: I intentionally do not preallocate a regional static IP here because
that caused errors when creating the VM in a different region than the
reserved address. The VM will receive an ephemeral external IP via
`access_config` which is sufficient for a demo. If you require a static
regional IP, create one per-region and supply it via a variable.
*/

resource "google_compute_instance" "kestra_vm" {
  count        = var.create_kestra_vm ? 1 : 0
  name         = var.kestra_vm_name
  zone         = var.kestra_vm_zone
  machine_type = var.kestra_vm_machine_type

  boot_disk {
    initialize_params {
      image = "ubuntu-2204-lts"
      size  = 30
      type  = "pd-standard"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata_startup_script = <<-EOF
    #!/bin/bash
    set -e
    apt-get update
    apt-get install -y docker.io docker-compose git
    systemctl enable docker
    systemctl start docker
    if [ -n "${var.kestra_repo_url}" ]; then
      rm -rf /opt/breathe-flow-pipeline || true
      git clone "${var.kestra_repo_url}" /opt/breathe-flow-pipeline || true
      cd /opt/breathe-flow-pipeline/kestra || exit 0
      docker compose pull || true
      docker compose up -d || true
    fi
  EOF

  service_account {
    email  = google_service_account.kestra.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  tags = ["kestra-ui"]
}

# Firewall rule to allow Kestra UI/API ports
resource "google_compute_firewall" "kestra_ui" {
  count = var.create_kestra_vm ? 1 : 0
  name    = "allow-kestra-ui"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["8080", "8081"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["kestra-ui"]
}

output "kestra_vm_external_ip" {
  value       = google_compute_instance.kestra_vm[0].network_interface[0].access_config[0].nat_ip
  description = "External IP address for the Kestra VM (if created)"
}
