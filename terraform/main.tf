locals {
  timestamp = formatdate("MM_DD_YY:hh_mm_ss", timestamp())
	root_dir = abspath("../")
}

terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "2.15.0"
    }
  }
}
provider "google" {
  credentials = file(var.credentials)

  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone
}
provider "google-beta" {
  credentials = file(var.credentials)

  project = var.google_project
  region  = var.google_region
  zone    = var.google_zone
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
  registry_auth {
    address = "us-central1-docker.pkg.dev"
    config_file = file(var.credentials)
  }

}

# Topic and subscription
resource "google_pubsub_topic" "osr_import_topic" {
  provider = google
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
  # I would've prefered to do this by linking a github repo to gcp but I kept running into issues
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
  provider       = google
  service_name   = "ms-api.endpoints.${var.google_project}.cloud.goog"
  openapi_config = file("./endpoints.yaml")
}

# Web UI
resource "google_artifact_registry_repository" "msrepo" {
  provider = google-beta

  location = "us-central1"
  repository_id = "message-store-repo"
  format = "DOCKER"
}

resource "docker_image" "ms_ui" {
  provider = docker
  name = "${google_artifact_registry_repository.msrepo.repository_id}"
  build {
    path = "../"
    dockerfile  = "./Dockerfile"
    # This is just to refresh the docker image so it builds on push
    label = {"timestamp": timestamp()}
    build_arg = {
      GOOGLE_CLOUD_PROJECT : var.google_project
    }
  }
}

# I really should've just done in this a script file
resource "null_resource" "docker_push" {
  triggers = {
    always_run = timestamp()
  }
  depends_on = [
    docker_image.ms_ui,
  ]
  provisioner "local-exec" {
    working_dir = local.root_dir
    command     = "gcloud auth activate-service-account jwtakeoff@roi-takeoff-user44.iam.gserviceaccount.com --key-file=terraform/${var.credentials} && gcloud auth print-access-token | docker login -u oauth2accesstoken --password-stdin https://${var.google_region}-docker.pkg.dev && docker tag ${docker_image.ms_ui.name} gcr.io/${var.google_project}/${docker_image.ms_ui.name} && docker push gcr.io/${var.google_project}/${docker_image.ms_ui.name}"
  }
}

resource "google_cloud_run_service" "ms_web_ui" {
  name     = "message-store-ui"
  location = var.google_region
  template {
    spec {
      containers {
        image = "${docker_image.ms_ui.repo_digest}"
        env {
          name = "GOOGLE_CLOUD_PROJECT"
          value = var.google_project
        }

      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  depends_on = [
    null_resource.docker_push,
  ]
}
