CREATE TABLE surf_construite AS
WITH
grid AS (
    SELECT geom
    FROM grid_ocs
    WHERE gid = 1
),
bati AS (
    SELECT t.geom AS geom FROM bdt.bdt_bati_indifferencie t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_bati_remarquable t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_bati_industriel t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_bati_remarquable t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_construction_legere t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_construction_lineaire t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_construction_surfacique t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_cimetiere t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_reservoir t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_terrain_sport t WHERE st_intersects(geom, (SELECT geom FROM grid))
    UNION SELECT t.geom AS geom FROM bdt.bdt_piste_aerodrome t WHERE st_intersects(geom, (SELECT geom FROM grid))
),
-- selection AS (
--     SELECT st_multi(geom) AS geom
--     FROM bati
--     WHERE st_intersects(geom, (SELECT geom FROM grid))
-- ),
dilatation AS (
    SELECT st_buffer(geom, 25) AS geom
    FROM bati
),
erosion AS (
    SELECT st_buffer(st_union(geom), -20) AS geom
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
SELECT row_number() over() AS gid, removeHoles(geom, 500) as geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE surf_construite
ADD PRIMARY KEY (gid);

CREATE INDEX surf_construite_geom_idx
ON surf_construite USING GIST (geom);

CREATE TABLE surf_construite_nino AS
WITH
intersection AS (
    SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
    FROM surf_construite a LEFT JOIN surf_nino b
    ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, geom
FROM intersection;

CREATE TABLE surf_construite_snapped AS
WITH
parts AS (
    SELECT SnapOnNino(2500, 5) as geom
)
SELECT row_number() over() AS gid, geom
FROM parts;

ALTER TABLE surf_construite_snapped
ADD PRIMARY KEY (gid);