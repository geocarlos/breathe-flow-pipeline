output "kestra_service_account_email" {
  description = "Email of the Kestra service account"
  value       = google_service_account.kestra.email
}

output "kestra_service_account_key_json" {
  description = "Service account key JSON for the Kestra SA (sensitive). Only present if var.create_kestra_sa_key = true."
  value       = try(google_service_account_key.kestra_key[0].private_key, "")
  sensitive   = true
}
