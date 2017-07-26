CREATE TABLE surf_construite_nofor AS
WITH
foret AS (
    SELECT geom
    FROM surf_foret_snapped
    WHERE st_area(geom) >= 5000
),
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom), 0.5), a.geom) AS geom
    FROM surf_construite_snapped a
    LEFT JOIN foret b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon' ;

CREATE TABLE surf_foret_noco AS
WITH
diff AS (
    SELECT a.gid, coalesce(safe_difference(a.geom, safe_union(b.geom), 0.5), a.geom) AS geom
    FROM surf_foret_snapped a
    LEFT JOIN surf_construite_nofor b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
),
parts AS (
    SELECT (st_dump(geom)).geom
    FROM diff
)
SELECT row_number() over() AS gid, geom
FROM parts
WHERE ST_GeometryType(geom) = 'ST_Polygon' ;