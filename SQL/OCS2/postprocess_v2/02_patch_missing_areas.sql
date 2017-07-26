CREATE TABLE patched AS
WITH
missing AS (
    SELECT (st_dump(st_difference((SELECT geom FROM grid_ocs WHERE gid = 1), st_union(a.geom)))).geom
    FROM simplified a
)
SELECT 'AUTRE/?' as nature, geom FROM missing
WHERE st_area(geom) > 500
UNION ALL
SELECT trim(nature) AS nature, geom FROM simplified;