data "ns_connection" "network" {
  name     = "network"
  contract = "network/gcp/vpc"
  via      = data.ns_connection.postgres.name
}

locals {
  private_subnets_ids = data.ns_connection.network.outputs.private_subnets_ids
}
