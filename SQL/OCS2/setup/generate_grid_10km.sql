-- Pour un seul département

INSERT INTO ocs.grid_ocs (geom, geohash)
WITH
depart AS (
    SELECT 'HAUTE-SAVOIE'::text AS name
),
extent AS (
    SELECT st_extent(geom) AS geom
    FROM bdt.bdt_commune
    WHERE depart = (SELECT name FROM depart)
),
points AS (
    SELECT (st_dumppoints(geom)).geom
    FROM extent
),
minmax AS (
    SELECT min(st_x(geom)) as minx,
           min(st_y(geom)) as miny,
           max(st_x(geom)) as maxx,
           max(st_y(geom)) as maxy
    FROM points
),
rounded AS (
    SELECT div(minx::numeric, 1e4) * 1e4 AS minx,
           div(miny::numeric, 1e4) * 1e4 AS miny,
           (div(maxx::numeric, 1e4) + 1) * 1e4 AS maxx,
           (div(maxy::numeric, 1e4) + 1) * 1e4 AS maxy
    FROM minmax
),
x AS (
    SELECT generate_series(minx, maxx, 1e4) as c
    FROM rounded
),
y AS (
    SELECT generate_series(miny, maxy, 1e4) as c
    FROM rounded
),
grid AS (
    SELECT st_setsrid(st_makebox2d(st_makepoint(x.c, y.c), st_makepoint(x.c + 1e4, y.c + 1e4)), 2154) AS geom
    FROM x, y
)
SELECT geom, st_geohash(st_transform(st_centroid(geom), 4326), 6) AS geohash
FROM grid
WHERE EXISTS (
    SELECT a.gid
    FROM bdt.bdt_commune a
    WHERE depart = (SELECT name FROM depart) AND st_intersects(a.geom, grid.geom)
);

-- Pour tous les départements

INSERT INTO ocs.grid_ocs (geom, geohash)
WITH
extent AS (
    SELECT st_extent(geom) AS geom
    FROM bdt.bdt_commune
),
points AS (
    SELECT (st_dumppoints(geom)).geom
    FROM extent
),
minmax AS (
    SELECT min(st_x(geom)) as minx,
           min(st_y(geom)) as miny,
           max(st_x(geom)) as maxx,
           max(st_y(geom)) as maxy
    FROM points
),
rounded AS (
    SELECT div(minx::numeric, 1e4) * 1e4 AS minx,
           div(miny::numeric, 1e4) * 1e4 AS miny,
           (div(maxx::numeric, 1e4) + 1) * 1e4 AS maxx,
           (div(maxy::numeric, 1e4) + 1) * 1e4 AS maxy
    FROM minmax
),
x AS (
    SELECT generate_series(minx, maxx, 1e4) as c
    FROM rounded
),
y AS (
    SELECT generate_series(miny, maxy, 1e4) as c
    FROM rounded
),
grid AS (
    SELECT st_setsrid(st_makebox2d(st_makepoint(x.c, y.c), st_makepoint(x.c + 1e4, y.c + 1e4)), 2154) AS geom
    FROM x, y
)
SELECT geom, st_geohash(st_transform(st_centroid(geom), 4326), 6) AS geohash
FROM grid
WHERE EXISTS (
    SELECT a.gid
    FROM bdt.bdt_commune a
    WHERE st_intersects(a.geom, grid.geom)
);

WITH dept AS (
  SELECT a.gid, b.depart AS name
  FROM ocs.grid_ocs a INNER JOIN bdt.bdt_commune b ON st_contains(b.geom, st_centroid(a.geom))
)
UPDATE ocs.grid_ocs
SET dept = dept.name
FROM dept
WHERE grid_ocs.gid = dept.gid;

WITH dept AS (
  SELECT a.gid, b.depart AS name
  FROM ocs.grid_ocs a LEFT JOIN bdt.bdt_commune b ON st_contains(b.geom, st_centroid(a.geom))
)
UPDATE ocs.grid_ocs
SET boundary = true
FROM dept
WHERE grid_ocs.gid = dept.gid AND dept.name IS NULL;

CREATE TABLE ocs.grid_ocs_boundary AS
WITH clip AS (
  SELECT a.gid, b.depart AS dept, st_intersection(a.geom, st_union(b.geom)) AS geom
  FROM ocs.grid_ocs a LEFT JOIN bdt.bdt_commune b ON st_intersects(a.geom, b.geom)
  WHERE a.boundary
  GROUP BY a.gid, b.depart
),
parts AS (
  SELECT gid, dept, (st_dump(geom)).geom
  FROM clip
)
SELECT gid, geom, dept
FROM parts;

DELETE FROM ocs.grid_ocs WHERE boundary;

INSERT INTO ocs.grid_ocs (geom, dept, geohash, boundary)
SELECT geom, dept, st_geohash(st_transform(st_centroid(geom), 4326), 6) AS geohash, true
FROM ocs.grid_ocs_boundary;

DROP TABLE ocs.grid_ocs_boundary;

CREATE OR REPLACE FUNCTION merge_tiles(tid bigint, target bigint)
RETURNS VOID
AS
$func$
DECLARE
BEGIN

UPDATE ocs.grid_ocs
SET geom = (SELECT st_union(geom) AS geom
  FROM ocs.grid_ocs
  WHERE gid = tid OR gid = target)
WHERE gid = target;

DELETE FROM ocs.grid_ocs
WHERE gid = tid;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;