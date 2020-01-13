
CREATE SCHEMA test_schema_create_drop;

CREATE TABLE test_schema_create_drop.example_table (
  name text
);

DROP SCHEMA test_schema_create_drop CASCADE;
