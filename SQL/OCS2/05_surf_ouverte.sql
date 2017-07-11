SET search_path = test, ocs, public;

CREATE TABLE surf_ouverte AS
WITH
foret AS (
    SELECT geom
    FROM surf_foret_snapped
    WHERE st_area(geom) >= 2500
),
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom)), a.geom) AS geom
    FROM surf_nino a LEFT JOIN foret b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom, st_area(geom), st_geometrytype(geom)
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon'
      AND st_area(geom) >= 2500;

ALTER TABLE surf_ouverte
ADD PRIMARY KEY (gid);

CREATE INDEX surf_ouverte_geom_idx
ON surf_ouverte USING GIST (geom);
