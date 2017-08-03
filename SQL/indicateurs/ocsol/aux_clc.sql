CREATE TABLE aux.clc_2012_clipped AS
WITH
clip AS (
    SELECT b.gid, a.code_12, st_intersection(a.geom, b.geom) AS geom
    FROM ref.clc_2012 a
    INNER JOIN ocs.grid_ocs b
    ON st_intersects(a.geom, b.geom)
),
parts AS (
    SELECT gid, code_12, (st_dump(geom)).geom
    FROM clip
)
SELECT row_number() over() AS gid, gid AS cid, code_12, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE aux.clc_2012_clipped
ADD PRIMARY KEY (gid);

CREATE INDEX clc_2012_clipped_geom_idx
ON aux.clc_2012_clipped USING GIST (geom);