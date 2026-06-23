variable "enabled" {
  type        = bool
  default     = true
  description = <<EOF
Whether the Datastream stream actively replicates data.
When `true` (the default) the stream runs; set it to `false` to pause replication without destroying the stream or its configuration.
EOF
}

variable "data_freshness" {
  type        = string
  default     = "900s"
  description = <<EOF
Maximum acceptable staleness of the BigQuery replica, expressed as a duration in seconds (e.g. `900s`).
Datastream merges pending changes into BigQuery at least this often.
Lower values reduce lag at the cost of more frequent (and more expensive) BigQuery write operations.
EOF
}

variable "postgres_username" {
  type        = string
  description = <<EOF
Username Datastream uses to connect to the source Postgres database.
The user must have `REPLICATION` privileges and read access to the tables being replicated.
EOF
}

variable "postgres_password" {
  type        = string
  sensitive   = true
  description = <<EOF
Password Datastream uses to connect to the source Postgres database.
This value supports `{{ secret(...) }}` interpolation to reference a secret stored in Nullstone.

```yaml
vars:
  postgres_password: "{{ secret(POSTGRES_PASSWORD) }}"
```
EOF
}

variable "postgres_database" {
  type        = string
  description = <<EOF
Name of the source Postgres database Datastream connects to and replicates from.
EOF
}

variable "replication_publication" {
  type        = string
  description = <<EOF
The name of the Postgres publication that lists the tables to replicate.
This must already exist on the source database (e.g. `CREATE PUBLICATION <name> FOR ALL TABLES;`).
EOF
}

variable "replication_slot" {
  type        = string
  description = <<EOF
The name of the Postgres logical replication slot Datastream reads changes from.
This must already exist on the source database and use the `pgoutput` plugin
(e.g. `SELECT pg_create_logical_replication_slot('<name>', 'pgoutput');`).
EOF
}

variable "replication_objects" {
  type = list(object({
    schema : string
    tables : optional(list(string))
  }))
  default     = [{ schema = "public" }]
  description = <<EOF
The set of Postgres schemas (and, optionally, specific tables) to replicate into BigQuery.
Each entry selects a schema; when `tables` is omitted or empty, every table in that schema is replicated.
The default replicates every table in the `public` schema.
Set the list to empty (`[]`) to replicate every table in every schema.

Example:
```
replication_objects = [
  { schema = "public" },
  { schema = "billing", tables = ["invoices", "payments"] },
]
```
EOF
}
