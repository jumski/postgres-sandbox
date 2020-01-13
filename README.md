# Postgres Sandbox

#### Requirements

* docker
* docker-compose

#### Main idea

*postgres-sandbox* provides small helper methods to easily test various
postgres functionalities in separation and with easy reproducible environments.

#### Creating a new sandbox

Sandboxes are just top-level directories. Each sandbox should be tied to some
theme. For example, to fiddle with database triggers, one would create a directory
`triggers/`.

#### Setting schema and initial data

All non-moving parts that should be run once for given sandbox should be put in
`sandbox_name/_setup.sql` file (queries like `CREATE TABLE`,
`CREATE FUNCTION`, `INSERT` etc.).

To create the sandbox and populate it from `_setup.sql` one would just run
`bin/setup sandbox_name` (in this particular example `bin/setup triggers/`).

This script recreates the schema for given sandbox (named `sandbox_triggers`
in this example) and will then run `_setup.sql` script in the context
of newly created schema.

#### Creating testing scripts

To run various queries against the just-setup schema, one would just create
multiple scripts in the sandbox folder, for example
`triggers/test_insert_on_users.sql`.

Then user can run those with `bin/run triggers/test_insert_on_users.sql`.
Those files will be run in context of `sandbox_triggers` schema (the `search_path`
will be set to this value before executing sql file).

This allows to test various things and easily start with clean environment
by just executing `bin/setup triggers/`.
