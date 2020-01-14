\qecho '---------- Schema setup ------------'

CREATE schema IF NOT EXISTS test_functions;
SET search_path TO test_update_triggers;

-- array subtraction function
CREATE OR REPLACE FUNCTION test_function(a INT) RETURNS INT AS
$body$
BEGIN
  RETURN a + a;
END;
$body$ LANGUAGE plpgsql;

-- array subtraction function
CREATE OR REPLACE FUNCTION test_function(a NUMERIC) RETURNS NUMERIC AS
$body$
BEGIN
  RETURN a - a;
END;
$body$ LANGUAGE plpgsql;

SELECT test_function(3.0);

DROP FUNCTION test_function;
