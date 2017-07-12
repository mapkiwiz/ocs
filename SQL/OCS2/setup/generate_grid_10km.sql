INSERT INTO ocs.grid_ocs (geom)
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