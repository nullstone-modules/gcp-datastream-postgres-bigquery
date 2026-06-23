data "ns_connection" "bigquery" {
  name     = "bigquery"
  contract = "datastore/gcp/bigquery"
}

locals {
  bigquery_project_id = data.ns_connection.bigquery.outputs.project_id
  bigquery_dataset_id = data.ns_connection.bigquery.outputs.dataset_id
}
