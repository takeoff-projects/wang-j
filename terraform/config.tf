variable "google_project" {
  type    = string
  default = "roi-takeoff-user44"
}

variable "google_region" {
  type    = string
  default = "us-central1"
}

variable "google_zone" {
  type    = string
  default = "us-central1-c"
}

variable "credentials" {
  type    = string
  default = "roi-takeoff-user44-0682ff3fdc4f.json"
}

variable "service_account" {
  type    = string
  default = "jwtakeoff@roi-takeoff-user44.iam.gserviceaccount.com"
}
