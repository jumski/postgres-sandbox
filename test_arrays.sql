
-- arrays vs rows
SELECT ARRAY[1,2,3];
SELECT UNNEST(ARRAY[1,3,3]);
SELECT ARRAY(SELECT 1);

-- array subtraction
CREATE OR replace FUNCTION array_subtract(minuend NUMERIC[], subtrahend NUMERIC[]) RETURNS text[] AS
$body$
BEGIN
  RETURN (SELECT ARRAY(SELECT UNNEST(minuend) EXCEPT SELECT UNNEST(subtrahend)))::NUMERIC[];
END;
$body$ LANGUAGE plpgsql;

SELECT array_subtract(ARRAY[1,2,3], ARRAY[1,2]);

-- for and foreach loops
DO
$do$
DECLARE
  item NUMERIC;
  arr NUMERIC[] := ARRAY[1,2,3,4,5];
BEGIN
  FOR item IN SELECT UNNEST(arr)
  LOOP
    raise notice 'for loop %', item;
  END LOOP;

  FOREACH item IN ARRAY arr
  LOOP
    raise notice 'foreach loop %', item;
  END LOOP;
END;
$do$
