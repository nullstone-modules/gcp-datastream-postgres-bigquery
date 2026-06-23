data "ns_workspace" "this" {}

// Generate a random suffix to ensure uniqueness of resources
resource "random_string" "resource_suffix" {
  length  = 5
  lower   = true
  upper   = false
  numeric = false
  special = false
}

locals {
  labels          = data.ns_workspace.this.gcp_labels
  block_name      = data.ns_workspace.this.block_name
  block_ref       = data.ns_workspace.this.block_ref
  resource_suffix = random_string.resource_suffix.result
  resource_name   = "${local.block_ref}-${local.resource_suffix}"
}
