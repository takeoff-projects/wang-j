locals {
  timestamp = formatdate("MM_DD_YY:hh_mm_ss", timestamp())
	root_dir = abspath("../")
}

provider "google" {
  credentials = file("roi-takeoff-user44-0682ff3fdc4f.json")

  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone
}

# Topic and subscription
resource "google_pubsub_topic" "osr_import_topic" {
  name = "osr-import"
}

# Get code and use it to create cloud function 
data "archive_file" "ms_code_zip" {
  type        = "zip"
  source_dir  = "${local.root_dir}/go/src/cf"
  output_path = "${local.timestamp}.zip"
}

resource "google_storage_bucket" "ms_code_bucket" {
  provider = google
  name     = "message-store-code-bucket"
}
resource "google_storage_bucket_object" "ms_code" {
  provider = google
  # Append file MD5 to force bucket to be recreated   
  name     = "ms.zip#${data.archive_file.ms_code_zip.output_md5}"
  bucket   = google_storage_bucket.ms_code_bucket.name
  source   = data.archive_file.ms_code_zip.output_path
}

resource "google_cloudfunctions_function" "osr_import_func" {
  provider = google
  name     = "osr-import-tracker"
  runtime  = "go113"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.ms_code_bucket.name
  source_archive_object = google_storage_bucket_object.ms_code.name
  entry_point           = "ProcessOsrImport"
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.osr_import_topic.name
  }
}
resource "google_cloudfunctions_function" "get_import_msg_func" {
  provider = google
  name     = "import-message-getter"
  runtime  = "go113"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.ms_code_bucket.name
  source_archive_object = google_storage_bucket_object.ms_code.name
  entry_point           = "GetOsrImportMessages"
  trigger_http          = true
}

# API Gateway
resource "google_endpoints_service" "ms_api_service" {
  service_name   = "ms-api.endpoints.${var.google_project}.cloud.goog"
  openapi_config = file("./endpoints.yaml")
}
