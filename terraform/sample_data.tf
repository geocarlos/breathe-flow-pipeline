resource "google_storage_bucket_object" "sample_raw" {
  name   = "raw/sample-0001.json"
  bucket = google_storage_bucket.data-lake-bucket.name
  content = <<-EOF
  {"location":"test","parameter":"pm25","value":12.3,"unit":"µg/m3","timestamp":"2026-04-18T00:00:00Z"}
  EOF
  content_type = "application/json"
}
