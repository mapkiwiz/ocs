CREATE TABLE carto.surface_non_artificialisee AS
WITH
union_artificialisee AS (
	SELECT grid_id as gid, st_union(geom) as geom
	FROM carto.surface_artificialisee
	WHERE grid_id = 306
	GROUP BY grid_id
),
diff AS (
	SELECT (st_dump(st_difference(g.geom, u.geom))).geom
	FROM union_artificialisee u INNER JOIN ind.grid_10km_m g ON u.gid = g.gid
)
SELECT row_number() over() as gid, geom
FROM diff;

-- TODO
-- INSERT small parts INTO surface_artificialisee

DELETE FROM carto.surface_non_artificialisee
WHERE st_area(geom) < 1000;