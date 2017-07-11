
CREATE TABLE test.surf_eau AS
WITH
grid AS (
    SELECT geom
    FROM test.grid_ocs
    WHERE gid = 1
),
eau AS (
    SELECT (st_dump(st_union(st_intersection(a.geom, (SELECT geom FROM grid))))).geom as geom
    FROM bdt.bdt_surface_eau a
    WHERE st_intersects(a.geom, (SELECT geom FROM grid)) AND a.regime = 'Permanent'
)
SELECT row_number() over() as gid, geom
FROM eau;

CREATE TABLE test.surf_eau_non_infra AS
WITH
intersection AS (
    SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
    FROM test.surf_eau a LEFT JOIN test.surf_non_infra b
    ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, geom
FROM intersection;

CREATE TABLE test.surf_eau_snapped AS
WITH parts AS (
	SELECT SnapOnLineNonInfra(geom, 2500, 5) AS geom
	FROM test.surf_eau_non_infra
)
SELECT row_number() over() AS gid, geom
FROM parts;