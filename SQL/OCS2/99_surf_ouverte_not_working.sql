-- CREATE TEMP TABLE surf_ouverte_t AS
-- WITH
-- grid AS (
--     SELECT geom
--     FROM test.grid_ocs
--     WHERE gid = 1
-- ),
-- surf_fermee AS (
--     SELECT geom FROM test.surf_construite
--     UNION ALL
--     SELECT geom FROM test.surf_infra
--     UNION ALL
--     SELECT geom FROM test.surf_foret
-- ),
-- diff AS (
--     SELECT st_difference((SELECT geom FROM grid), st_union(geom)) AS geom
--     FROM surf_fermee
--     -- WHERE ...
-- ),
-- parts AS (
--     SELECT (st_dump(geom)).geom
--     FROM diff
-- )
-- SELECT row_number() over() AS gid, geom
-- FROM parts
-- WHERE ST_GeometryType(geom) = 'ST_Polygon';

CREATE INDEX surf_construite_geom_idx
ON test.surf_construite USING GIST (geom);

CREATE INDEX surf_foret_geom_idx
ON test.surf_foret USING GIST (geom);

CREATE INDEX surf_eau_geom_idx
ON test.surf_eau USING GIST (geom);

CREATE TABLE test.surf_eau_urbain_infra AS
WITH
eau_urbain_infra AS (
    SELECT geom FROM test.surf_construite_snapped
    UNION ALL
    SELECT geom FROM test.surf_infra WHERE st_area(geom) > 2500
    UNION ALL
    SELECT geom FROM test.surf_eau_snapped
),
parts AS (
    SELECT (st_dump(st_union(geom))).geom AS geom
    FROM eau_urbain_infra
)
SELECT row_number() over() AS gid, removeHoles(geom, 2500) AS geom
FROM parts;

CREATE TEMP TABLE surf_ouverte_t AS
WITH
grid AS (
    SELECT geom
    FROM test.grid_ocs
    WHERE gid = 1
),
to_be_removed AS (
    SELECT a.gid, st_union(st_intersection(a.geom, b.geom)) AS geom
    FROM test.surf_non_infra a INNER JOIN test.surf_eau_urbain_infra b
         ON st_intersects(a.geom, b.geom)
    WHERE st_area(a.geom) > 2500
    GROUP BY a.gid
),
diff AS (
    SELECT a.gid, coalesce(st_difference(a.geom, b.geom), a.geom) AS geom
    FROM test.surf_non_infra a LEFT JOIN to_be_removed b
         ON a.gid = b.gid
    -- WHERE ...
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';