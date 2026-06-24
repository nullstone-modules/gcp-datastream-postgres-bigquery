resource "google_datastream_private_connection" "this" {
  display_name          = local.block_name
  location              = local.region
  private_connection_id = local.resource_name
  labels                = local.labels

  psc_interface_config {
    network_attachment = google_compute_network_attachment.datastream.id
  }

  depends_on = [google_project_service.datastream]
}

resource "google_datastream_connection_profile" "source" {
  display_name          = "${local.block_name} Postgres Source"
  location              = local.region
  connection_profile_id = "${local.block_ref}-postgres-source-${local.resource_suffix}"
  labels                = local.labels

  postgresql_profile {
    hostname = local.postgres_subdomain
    port     = local.postgres_port
    username = var.postgres_username
    password = local.postgres_password
    database = var.postgres_database
  }

  private_connectivity {
    private_connection = google_datastream_private_connection.this.id
  }

  depends_on = [google_project_service.datastream]
}

resource "google_datastream_connection_profile" "destination" {
  display_name          = "${local.block_name} BigQuery Destination"
  location              = local.region
  connection_profile_id = "${local.block_ref}-bigquery-dest-${local.resource_suffix}"
  labels                = local.labels

  bigquery_profile {}

  depends_on = [google_project_service.datastream]
}

resource "google_datastream_stream" "this" {
  display_name  = local.block_name
  location      = local.region
  stream_id     = local.resource_name
  labels        = local.labels
  desired_state = var.enabled ? "RUNNING" : "PAUSED"

  source_config {
    source_connection_profile = google_datastream_connection_profile.source.id

    postgresql_source_config {
      publication      = var.replication_publication
      replication_slot = var.replication_slot

      # When var.replication_objects is empty, include_objects is omitted entirely,
      # which tells Datastream to replicate every table in every schema.
      dynamic "include_objects" {
        for_each = length(var.replication_objects) > 0 ? [1] : []

        content {
          dynamic "postgresql_schemas" {
            for_each = var.replication_objects

            content {
              schema = postgresql_schemas.value.schema

              # No table entries for a schema => every table in that schema is streamed.
              dynamic "postgresql_tables" {
                for_each = coalesce(postgresql_schemas.value.tables, [])

                content {
                  table = postgresql_tables.value
                }
              }
            }
          }
        }
      }
    }
  }

  destination_config {
    destination_connection_profile = google_datastream_connection_profile.destination.id

    bigquery_destination_config {
      data_freshness = var.data_freshness

      # Merge mode (default): each BQ table is a current-state replica with
      # soft-deletes applied -- no "latest row" logic needed in the views.
      single_target_dataset {
        dataset_id = "${local.bigquery_project_id}:${local.bigquery_dataset_id}"
      }
    }
  }

  backfill_all {}

  depends_on = [google_project_service.datastream]
}
