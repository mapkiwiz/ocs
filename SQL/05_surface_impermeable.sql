DROP TABLE IF EXISTS carto.surface_impermeable CASCADE;

CREATE TABLE carto.surface_impermeable AS
WITH
to_be_removed AS (
	SELECT a.gid, st_union(st_intersection(a.geom, b.geom)) AS geom
	FROM carto.surface_urbanisee a INNER JOIN carto.surface_eau b ON a.cid = b.cid AND st_intersects(a.geom, b.geom)
	GROUP BY a.gid
),
diff AS (
	SELECT a.gid, a.cid, (st_dump(coalesce(st_difference(a.geom, r.geom), a.geom))).geom AS geom
	FROM carto.surface_urbanisee a LEFT JOIN to_be_removed r ON a.gid = r.gid
)
SELECT row_number() over() as gid, cid, diff.geom
FROM diff;