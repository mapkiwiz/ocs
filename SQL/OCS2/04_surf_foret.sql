CREATE TABLE test.surf_foret AS
WITH
grid AS (
    SELECT geom
    FROM test.grid_ocs
    WHERE gid = 1
),
foret AS (
    SELECT geom
    FROM bdt.bdt_zone_vegetation a
    WHERE  st_intersects(geom, (SELECT geom FROM grid))
           AND ( nature = 'Bois'
                 OR nature = 'Zone arborée'
                 OR nature LIKE 'Forêt fermée%' )
),
dilatation AS (
    SELECT st_buffer(geom, 10) AS geom
    FROM foret
),
erosion AS (
    SELECT st_buffer(st_union(geom), -10) AS geom
    FROM dilatation
),
clip AS (
    SELECT st_intersection(geom, (SELECT geom FROM grid)) AS geom
    FROM erosion
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM clip
)
SELECT row_number() over() AS gid, geom
FROM parts;

CREATE TEMP TABLE surf_foret_non_infra_t AS
WITH
intersection AS (
    SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
    FROM test.surf_foret a LEFT JOIN test.surf_non_infra b
    ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, geom
FROM intersection;

CREATE TABLE test.surf_foret_non_infra AS
WITH parts AS (
    SELECT SplitWithNetworks(geom) as geom
    FROM surf_foret_non_infra_t
)      
SELECT row_number() over() AS gid, geom
FROM parts;

CREATE TABLE test.surf_foret_snapped AS
WITH parts AS (
	SELECT SnapOnLineNonInfra(geom, 2500, 5) AS geom
	FROM test.surf_foret_non_infra
)
SELECT row_number() over() AS gid, geom
FROM parts;