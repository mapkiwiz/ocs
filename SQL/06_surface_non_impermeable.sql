DROP TABLE IF EXISTS carto.surface_non_impermeable CASCADE;

CREATE TABLE carto.surface_non_impermeable AS
WITH
urbanisee_et_eau AS (
	SELECT cid, geom FROM carto.surface_urbanisee
	UNION
	SELECT cid, geom FROM carto.surface_eau
),
to_be_removed AS (
	SELECT a.gid, safe_union(safe_intersection(a.geom, b.geom)) AS geom
	FROM ind.grid_10km_m a INNER JOIN urbanisee_et_eau b ON a.gid = b.cid
	GROUP BY a.gid
),
diff AS (
	SELECT a.gid as cid, (st_dump(coalesce(safe_difference(a.geom, r.geom), a.geom))).geom AS geom
	FROM ind.grid_10km_m a LEFT JOIN to_be_removed r ON a.gid = r.gid
)
SELECT row_number() over() as gid, cid, diff.geom
FROM diff;

INSERT INTO carto.surface_urbanisee (gid, cid, geom)
SELECT row_number() over() + (SELECT max(gid) FROM carto.surface_urbanisee) as gid, cid, geom
FROM carto.surface_non_impermeable
WHERE st_area(geom) < 1500;

DELETE FROM carto.surface_non_impermeable
WHERE st_area(geom) < 1500;