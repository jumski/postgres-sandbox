\qecho '---------- Schema setup ------------'

CREATE schema IF NOT EXISTS test_update_triggers;
SET search_path TO test_update_triggers;
DROP TABLE IF EXISTS group_events CASCADE;
DROP TABLE IF EXISTS groups CASCADE;

CREATE TABLE IF NOT EXISTS groups (
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  transition_state text,
  statuses text[] DEFAULT '{}'::text[] NOT NULL,
  premium_value NUMERIC NOT NULL
);
CREATE TABLE IF NOT EXISTS group_events (
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  event_date timestamptz NOT NULL,
  event_name text NOT NULL,
  group_id int references groups(id)
);

-- fail on any errors below
\set ON_ERROR_STOP TRUE

-- array subtraction function
CREATE OR replace FUNCTION array_subtract(minuend text[], subtrahend text[]) RETURNS text[] AS
$body$
BEGIN
  RETURN (SELECT ARRAY(SELECT UNNEST(minuend) EXCEPT SELECT UNNEST(subtrahend)))::text[];
END;
$body$ LANGUAGE plpgsql;

-- trigger that watches updates to `groups` table and creates new events
CREATE OR REPLACE FUNCTION create_group_event() RETURNS TRIGGER AS
$body$
DECLARE
  added_statuses text[] := array_subtract(NEW.statuses, OLD.statuses);
  removed_statuses text[] := array_subtract(OLD.statuses, NEW.statuses);
  transition_state_changed BOOLEAN := OLD.transition_state != NEW.transition_state;
  is_prospect BOOLEAN := NEW.transition_state = 'prospect';
BEGIN
  -- special case - adding 'quoted' status to prospect,
  -- creates `convert_to_quoted_prospect` transition
  IF is_prospect AND added_statuses @> ARRAY['quoted'] THEN
    INSERT INTO group_events(event_date, event_name, group_id)
      VALUES(NOW(), 'convert_to_quoted_prospect', NEW.id);
  END IF;

  -- transition_state changes
  IF transition_state_changed THEN
    INSERT INTO group_events(event_date, event_name, group_id)
      VALUES(NOW(), 'convert_to_' || NEW.transition_state, NEW.id);
  END IF;

  -- add/remove statuses
  INSERT INTO group_events(event_date, event_name, group_id)
    SELECT NOW(), 'add_status_' || status_name, NEW.id
    FROM UNNEST(added_statuses) AS status_name
    UNION ALL
    SELECT NOW(), 'remove_status_' || status_name, NEW.id
    FROM UNNEST(removed_statuses) AS status_name;

  RETURN NEW;
END;
$body$ language plpgsql;

CREATE TRIGGER create_group_event_trigger
  AFTER UPDATE
  ON groups
  FOR EACH ROW
  EXECUTE PROCEDURE create_group_event();

INSERT INTO groups(transition_state, premium_value, statuses) VALUES ('lead', 100, ARRAY['new']), ('prospect', 200, ARRAY['hot']), ('customer', 300, ARRAY['cold']);
SELECT * FROM groups;
SELECT * FROM group_events;

UPDATE groups SET statuses = array_append(statuses, 'quoted') WHERE transition_state = 'prospect';
UPDATE groups SET transition_state = 'customer' WHERE transition_state = 'prospect';
UPDATE groups SET transition_state = 'prospect' WHERE transition_state = 'lead';
UPDATE groups SET premium_value = 200 WHERE premium_value = 100;
UPDATE groups SET statuses = array_append(statuses, 'quoted') WHERE transition_state = 'customer';
UPDATE groups SET statuses = array_append(statuses, 'new')    WHERE transition_state = 'customer';
UPDATE groups SET statuses = array_append(statuses, 'hot')    WHERE transition_state = 'customer';
UPDATE groups SET statuses = array_remove(statuses, 'quoted') WHERE transition_state = 'customer';
UPDATE groups SET statuses = array_remove(statuses, 'new')    WHERE transition_state = 'customer';
UPDATE groups SET statuses = array_append(statuses, 'quoted') WHERE transition_state = 'customer';
SELECT * FROM group_events;
