\qecho '---------- Schema setup ------------'
CREATE extension IF NOT EXISTS postgis;
explain SELECT PostGIS_Full_Version();

create schema if not exists test_postgis;
set search_path to test_postgis;


