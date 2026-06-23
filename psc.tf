resource "google_compute_network_attachment" "datastream" {
  name                  = local.resource_name
  region                = local.region
  connection_preference = "ACCEPT_AUTOMATIC"
  subnetworks           = local.private_subnets_ids

  depends_on = [google_project_service.compute]
}
