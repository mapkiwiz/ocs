
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
    SELECT SnapOnNonInfra(geom, 2500, 5) AS geom
    FROM test.surf_eau_non_infra
)
SELECT row_number() over() AS gid, geom
FROM parts;

CREATE TABLE test.surf_nino AS
WITH
diff AS (
    SELECT a.gid, coalesce(st_difference(a.geom, st_union(b.geom)), a.geom) AS geom
    FROM test.surf_non_infra a LEFT JOIN test.surf_eau b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon';

ALTER TABLE test.surf_nino
ADD PRIMARY KEY (gid);

CREATE INDEX surf_nino_geom_idx
ON test.surf_nino USING GIST (geom);