CREATE TABLE surf_foret AS
WITH
grid AS (
    SELECT geom
    FROM grid_ocs
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
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE surf_foret
ADD PRIMARY KEY (gid);

CREATE TABLE surf_foret_nino AS
WITH
intersection AS (
    SELECT a.gid, coalesce(st_intersection(a.geom, st_union(b.geom)), a.geom) AS geom
    FROM surf_foret a LEFT JOIN surf_nino b
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

-- CREATE TABLE surf_foret_nino AS
-- WITH parts AS (
--     SELECT SplitWithNetworks(geom) as geom
--     FROM surf_foret_nino_t
-- )      
-- SELECT row_number() over() AS gid, geom
-- FROM parts;

CREATE TABLE surf_foret_snapped AS
WITH snaps AS (
    SELECT SnapOnNino(geom, 2500, 5) AS geom
    FROM surf_foret_nino
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM snaps
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE surf_foret_snapped
ADD PRIMARY KEY (gid);