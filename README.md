# Postgres Sandbox

#### Requirements

* docker
* docker-compose

#### Setup

```bash
docker-compose up -d
```

#### Running `psql`

Use `bin/psql` to enter interactive mode:

```bash
bin/psql
```

Or pass it some scripts:

```bash
bin/psql < test_roles.sql
```

It also passes any arguments to `psql`:

```bash
bin/psql --quiet
```

## Running examples

Every example should create and use schema of its own filename (without extension)
You run examples by passing them to stdin of `bin/psql`, like this:

```bash
bin/psql < example_name.sql
```

### `test_roles.sql`

Sandbox for testing how roles and row level locking actually works.

### `test_updatable_views.sql`

Sandbox for testing automatic updatable views.

### `test_update_triggers.sql`

Sandbox for testing triggers.
