\qecho '---------- Schema setup ------------'

CREATE schema IF NOT EXISTS test_update_triggers;
SET search_path TO test_update_triggers;
DROP TABLE IF EXISTS group_events CASCADE;
DROP TABLE IF EXISTS groups CASCADE;

CREATE TABLE IF NOT EXISTS groups (
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  transition_state text,
  statuses text[] DEFAULT '{}'::text[] NOT NULL,
  lead_email_import_id INT,
  lead_api_import_id INT,
  organization_id INT,
  user_id INT,
  premium_value NUMERIC NOT NULL
);
CREATE TABLE IF NOT EXISTS group_events (
  id int GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
  event_date timestamptz NOT NULL,
  event_name text NOT NULL,
  group_id int references groups(id),
  user_id INT,
  organization_id INT
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
CREATE OR REPLACE FUNCTION create_group_changes_on_update() RETURNS TRIGGER AS
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
    INSERT INTO group_events(event_date, event_name, group_id, user_id, organization_id)
      VALUES(NOW(), 'convert_to_quoted_prospect', NEW.id, NEW.user_id, NEW.organization_id);
  END IF;

  -- transition_state changes
  IF transition_state_changed THEN
    INSERT INTO group_events(event_date, event_name, group_id, user_id, organization_id)
      VALUES(NOW(), 'convert_to_' || NEW.transition_state, NEW.id, NEW.user_id, NEW.organization_id);
  END IF;

  -- add/remove statuses
  INSERT INTO group_events(event_date, event_name, group_id, user_id, organization_id)
    SELECT NOW(), 'add_status_' || status_name, NEW.id, NEW.user_id, NEW.organization_id
    FROM UNNEST(added_statuses) AS status_name
    UNION ALL
    SELECT NOW(), 'remove_status_' || status_name, NEW.id, NEW.user_id, NEW.organization_id
    FROM UNNEST(removed_statuses) AS status_name;

  -- assigning user to internet lead
  IF OLD.user_id IS NULL AND NEW.user_id IS NOT NULL THEN
    INSERT INTO group_events(event_date, event_name, group_id, user_id, organization_id)
      VALUES(now(), 'convert_to_lead', NEW.id, NEW.user_id, NEW.organization_id);
  END IF;

  RETURN NEW;
END;
$body$ language plpgsql;

-- trigger that watches inserts to `groups` table and creates new events
CREATE OR REPLACE FUNCTION create_group_changes_on_insert() RETURNS TRIGGER AS
$body$
DECLARE
  event_name text;
BEGIN
  IF NEW.lead_email_import_id IS NOT NULL OR NEW.lead_api_import_id IS NOT NULL THEN
    event_name := 'create_internet_new_lead';
  ELSE
    event_name := 'create_lead';
  END IF;

  INSERT INTO group_events(event_date, event_name, group_id, user_id, organization_id)
    VALUES(NOW(), event_name, NEW.id, NEW.user_id, NEW.organization_id);

  RETURN NEW;
END;
$body$ LANGUAGE plpgsql;

CREATE TRIGGER create_group_changes_on_update
  AFTER UPDATE
  ON groups
  FOR EACH ROW
  EXECUTE PROCEDURE create_group_changes_on_update();

CREATE TRIGGER create_group_changes_on_insert
  AFTER INSERT
  ON groups
  FOR EACH ROW
  EXECUTE PROCEDURE create_group_changes_on_insert();

INSERT INTO groups(id, transition_state, premium_value, statuses, organization_id, user_id, lead_email_import_id, lead_api_import_id) VALUES
  -- regular lead (not null user_id, null lead_email_import_id and lead_api_import_id)
  (1, 'lead', 100, ARRAY['new'], 1, 1,    NULL, NULL),

  -- internet lead (null user_id, not null lead_email_import_id)
  (2, 'lead', 100, ARRAY['new'], 1, NULL, 7,    NULL);

\qecho '--- Removing statuses (gid 1)'
UPDATE groups SET statuses = array_remove(statuses, 'new')  WHERE id = 1;
UPDATE groups SET statuses = array_append(statuses, 'cold') WHERE id = 1;
UPDATE groups SET transition_state = 'prospect' WHERE id = 1;
UPDATE groups SET statuses = array_append(statuses, 'quoted') WHERE id = 1;
UPDATE groups SET transition_state = 'customer' WHERE id = 1;
SELECT * FROM group_events WHERE group_id = 1;

\qecho '--- Removing statuses (gid 1)'
UPDATE groups SET statuses = array_remove(statuses, 'new')  WHERE id = 2;
UPDATE groups SET statuses = array_append(statuses, 'cold') WHERE id = 2;
UPDATE groups SET user_id = 2 WHERE id = 2;
UPDATE groups SET transition_state = 'prospect' WHERE id = 2;
UPDATE groups SET statuses = array_append(statuses, 'quoted') WHERE id = 2;
UPDATE groups SET transition_state = 'customer' WHERE id = 2;
SELECT * FROM group_events WHERE group_id = 2;
