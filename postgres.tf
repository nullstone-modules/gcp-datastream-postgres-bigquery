data "ns_connection" "postgres" {
  name     = "postgres"
  contract = "datastore/gcp/postgres"
}

locals {
  postgres_endpoint  = data.ns_connection.postgres.outputs.db_endpoint
  postgres_subdomain = split(":", local.postgres_endpoint)[0]
  postgres_port      = split(":", local.postgres_endpoint)[1]
}

// Detect if var.postgres_password is a `{{ secret(<ref>) }}` reference vs. a plain value.
// `secret_refs["POSTGRES_PASSWORD"]` is populated only when the value matches the secret-ref pattern.
data "ns_env_variables" "interpolation" {
  input_env_variables = {}
  input_secrets = {
    POSTGRES_PASSWORD = var.postgres_password
  }
}

locals {
  postgres_password_secret_ref = lookup(data.ns_env_variables.interpolation.secret_refs, "POSTGRES_PASSWORD", "")
}

// When var.postgres_password is a secret reference, pull the value from Google Secret Manager.
data "google_secret_manager_secret_version" "postgres_password" {
  count = local.postgres_password_secret_ref != "" ? 1 : 0

  secret = local.postgres_password_secret_ref
}

locals {
  postgres_password = length(data.google_secret_manager_secret_version.postgres_password) > 0 ? data.google_secret_manager_secret_version.postgres_password[0].secret_data : var.postgres_password
}
