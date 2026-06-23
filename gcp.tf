data "google_client_config" "this" {}
data "google_project" "this" {}

locals {
  project_id = data.google_project.this.project_id
  region     = data.google_client_config.this.region
}

resource "google_project_service" "compute" {
  service                    = "compute.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}

resource "google_project_service" "datastream" {
  service                    = "datastream.googleapis.com"
  disable_dependent_services = false
  disable_on_destroy         = false
}
