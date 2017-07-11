CREATE TABLE carto.ocsol AS
WITH u AS (
    SELECT cid, geom, 'SURFACE IMPERMEABLE' AS type from carto.surface_impermeable
    UNION SELECT cid, geom, 'SURFACE EN EAU' AS type from carto.surface_eau
    UNION SELECT cid, geom, 'SURFACE BOISEE' AS type from carto.surface_boisee 
    UNION SELECT cid, geom, type from carto.surface_agricole
    UNION SELECT cid, geom, 'SURFACE AUTRE' AS type from carto.surface_autre
)
SELECT row_number() over() AS gid, cid, type, geom FROM u;

ALTER TABLE carto.ocsol
ADD PRIMARY KEY (gid);

CREATE INDEX ocsol_geom_idx
ON carto.ocsol USING GIST (geom);

CREATE TABLE carto.ocsol_306 AS
WITH p AS (
    SELECT a.gid, a.cid, a.type, (st_dump(safe_intersection(a.geom, b.geom, 0.001))).geom
    FROM carto.ocsol a INNER JOIN ind.grid_500m b
         ON st_intersects(a.geom, b.geom)
    WHERE a.cid = 306
)
SELECT * FROM p
WHERE st_geometrytype(geom) = 'ST_Polygon';

