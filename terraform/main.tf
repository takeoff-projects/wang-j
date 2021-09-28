locals {
  timestamp = formatdate("MM_DD_YY:hh_mm_ss", timestamp())
	root_dir = abspath("../")
}

terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  credentials = file("roi-takeoff-user44-0682ff3fdc4f.json")

  project = "roi-takeoff-user44"
  region  = "us-central1"
  zone    = "us-central1-c"
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
  name = "message-store-code-bucket"
}

resource "google_storage_bucket_object" "ms_code" {
  # Append file MD5 to force bucket to be recreated   name   = "source.zip#${data.archive_file.source.output_md5}"
  name   = "message-store-code"
  bucket = google_storage_bucket.ms_code_bucket.name
  source = data.archive_file.ms_code_zip.output_path
}

resource "google_cloudfunctions_function" "osr_import_func" {
  name    = "osr-import-tracker"
  runtime = "go113"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.ms_code_bucket.name
  source_archive_object = google_storage_bucket_object.ms_code.name
  entry_point           = "ProcessOsrImport"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource = google_pubsub_topic.osr_import_topic.name
  }
}
