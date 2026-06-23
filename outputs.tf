output "stream_id" {
  value       = google_datastream_stream.this.stream_id
  description = "string ||| The id of the Datastream stream."
}

output "stream_name" {
  value       = google_datastream_stream.this.name
  description = "string ||| The fully-qualified resource name of the Datastream stream."
}

output "stream_state" {
  value       = google_datastream_stream.this.state
  description = "string ||| The current state of the Datastream stream (e.g. `RUNNING`)."
}

output "private_connection_id" {
  value       = google_datastream_private_connection.this.id
  description = "string ||| The id of the Datastream private connection."
}

output "source_connection_profile_id" {
  value       = google_datastream_connection_profile.source.id
  description = "string ||| The id of the Postgres source connection profile."
}

output "destination_connection_profile_id" {
  value       = google_datastream_connection_profile.destination.id
  description = "string ||| The id of the BigQuery destination connection profile."
}

output "network_attachment_id" {
  value       = google_compute_network_attachment.datastream.id
  description = "string ||| The id of the network attachment Datastream uses to reach the source database over PSC."
}
