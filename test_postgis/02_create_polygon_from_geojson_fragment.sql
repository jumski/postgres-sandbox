\qecho '---------- Schema setup ------------'
CREATE extension IF NOT EXISTS postgis;
explain SELECT PostGIS_Full_Version();

/* create schema if not exists test_postgis; */
/* set search_path to test_postgis; */

---------------------------------
SELECT ST_AsText(ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[-96.802646,32.781506],[-96.801487,32.781746],[-96.801332,32.781484],[-96.801192,32.781013],[-96.801519,32.780952],[-96.801625,32.780924],[-96.802207,32.780822],[-96.802424,32.780776],[-96.802951,32.780672],[-96.803049,32.780648],[-96.803271,32.781337],[-96.802646,32.781506]]]}')) AS polygon;
