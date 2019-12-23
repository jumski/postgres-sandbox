# Postgres Sandbox

#### Requirements

* docker
* docker-compose

#### Setup

```bash
docker-compose up -d postgres
```

#### Interactive mode

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

