resource "google_storage_bucket_object" "sample_raw" {
  name   = "raw/sample-0001.json"
  bucket = google_storage_bucket.data-lake-bucket.name
  source = "${path.module}/sample_data/sample-0001.json"
  content_type = "application/json"
}
