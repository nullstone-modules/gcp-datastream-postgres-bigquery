# gcp-datastream-postgres-bigquery

Creates a [Google Cloud Datastream](https://cloud.google.com/datastream) pipeline that
continuously replicates change data from a PostgreSQL database into a BigQuery dataset.

This module wires together three Nullstone datastores:

- a **Postgres** source (`datastore/gcp/postgres`),
- a **BigQuery** destination (`datastore/gcp/bigquery`), and
- the **VPC network** (`network/gcp/vpc`) the source database lives in,

and provisions everything Datastream needs to move data between them: a private
connection, source/destination connection profiles, and the stream itself.

## How it connects

Datastream runs in a Google-managed project, so it reaches your database over
[Private Service Connect (PSC)](https://docs.cloud.google.com/datastream/docs/psc-interfaces)
rather than directly. This module creates a **network attachment** in the database's
private subnet and a Datastream **private connection** bound to it. The source
database must therefore be reachable over private networking — when using the
`gcp-cloudsql-postgres` module, provision it with `enable_psc = true`.

The Postgres connection profile connects to the database endpoint exposed by the
`postgres` connection (`db_endpoint`), authenticating with `var.postgres_username`,
`var.postgres_password`, and `var.postgres_database`. Reference a Nullstone secret for
the password using the `{{ secret(...) }}` interpolation so it is never stored in
plaintext config:

```yaml
vars:
  postgres_password: "{{ secret(POSTGRES_PASSWORD) }}"
```

## Prerequisites on the source database

Postgres logical replication must be configured on the source **before** you launch
this module — Datastream cannot create the stream otherwise. Complete the steps below
in order.

### 1. Enable logical decoding

Logical replication requires `wal_level >= logical`. On Cloud SQL for Postgres this is
controlled by the `cloudsql.logical_decoding` database flag — set it to `on` (e.g. with
the `gcp-cloudsql-postgres` module's flags input, or in the Cloud Console). Changing this
flag **requires a database restart**, so apply it first and let the instance come back up.

You can confirm it is active with:

```sql
SHOW wal_level;  -- should report: logical
```

### 2. Create the publication and replication slot

Once `wal_level` is `logical`, create the publication and logical replication slot that
Datastream reads from. Their names are passed to this module as
`var.replication_publication` and `var.replication_slot`:

```sql
-- Publication listing the tables to replicate
CREATE PUBLICATION nullstone_pub1 FOR ALL TABLES;

-- Logical replication slot using the pgoutput plugin
SELECT pg_create_logical_replication_slot('datastream_slot1', 'pgoutput');
```

### 3. Create the replication user

Create the user Datastream authenticates as (`var.postgres_username` /
`var.postgres_password`). It needs `REPLICATION` privileges and `SELECT` on the tables
being replicated:

```sql
CREATE USER datastream WITH REPLICATION LOGIN PASSWORD '...';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO datastream;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO datastream;
```

The `ALTER DEFAULT PRIVILEGES` statement ensures the user also gains `SELECT` on tables
created in the future, not just those that exist today. Repeat the two `GRANT`/`ALTER`
statements for any other schemas listed in `var.replication_objects`.

Pass this password to the module using `{{ secret(...) }}` interpolation so it is never
stored in plaintext config (see [How it connects](#how-it-connects) above).

## Selecting what to replicate

`var.replication_objects` controls which schemas and tables are streamed:

- The default (`[{ schema = "public" }]`) replicates **every table in the `public` schema**.
- Set it to empty (`[]`) to replicate **every table in every schema**.
- List a schema with no `tables` to replicate **all tables in that schema**.
- List specific `tables` under a schema to replicate **only those tables**.

```hcl
replication_objects = [
  { schema = "public" },
  { schema = "billing", tables = ["invoices", "payments"] },
]
```

## Destination layout

The stream writes to the dataset from the `bigquery` connection using Datastream's
**merge** mode (`single_target_dataset`). Each source table becomes a BigQuery
table that is kept as a current-state replica — inserts, updates, and soft-deletes
are merged in, so no "latest row" logic is needed when querying. `var.data_freshness`
controls how often those merges run (and therefore how fresh the replica is).

The stream is created with `backfill_all`, so existing rows are backfilled once
before ongoing change data is applied. By default it starts in the `RUNNING`
state and replicates as soon as it is created.

## Pausing replication

Set `var.enabled = false` to pause the stream (`desired_state = "PAUSED"`) without
destroying it or losing its configuration. Replication stops, but the stream,
connection profiles, and private connection are all left in place. Set it back to
`true` to resume.

## Outputs

| Output                              | Description                                                                    |
|-------------------------------------|--------------------------------------------------------------------------------|
| `stream_id`                         | The id of the Datastream stream.                                               |
| `stream_name`                       | The fully-qualified resource name of the Datastream stream.                    |
| `stream_state`                      | The current state of the Datastream stream (e.g. `RUNNING`).                   |
| `private_connection_id`             | The id of the Datastream private connection.                                   |
| `source_connection_profile_id`      | The id of the Postgres source connection profile.                              |
| `destination_connection_profile_id` | The id of the BigQuery destination connection profile.                         |
| `network_attachment_id`             | The id of the network attachment Datastream uses to reach the source over PSC. |
