CREATE TABLE surf_arboriculture AS
WITH
grid AS (
    SELECT geom
    FROM grid_ocs
    WHERE gid = 1
),
arbo AS (
    SELECT (st_dump(safe_intersection(st_makevalid(a.geom), (SELECT geom FROM grid), 0.5))).geom AS geom
    FROM ref.rpg_2014 a
    WHERE st_intersects(a.geom, (SELECT geom FROM grid))
          AND a.code_cultu IN ('20','22','23','27')
),
dilatation AS (
    SELECT st_buffer(geom, 5) AS geom
    FROM arbo
),
erosion AS (
    SELECT st_buffer(st_union(geom), -5) AS geom
    FROM dilatation
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM erosion
)
SELECT row_number() over() AS gid, geom
FROM parts;

ALTER TABLE surf_arboriculture
ADD PRIMARY KEY (gid);

CREATE TABLE surf_arboriculture_t AS
WITH
intersection AS (
    SELECT a.gid, coalesce(safe_intersection(a.geom, safe_union(b.geom), 0.5), a.geom) AS geom
    FROM surf_arboriculture a LEFT JOIN surf_ouverte b
    ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM intersection
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

CREATE TABLE surf_arboriculture_snapped AS
WITH
snaps AS (
    SELECT SnapOnSurfOuverte(geom, 2500, 10) AS geom
    FROM surf_arboriculture_t
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM snaps
)
SELECT row_number() over() AS gid, geom
FROM parts;