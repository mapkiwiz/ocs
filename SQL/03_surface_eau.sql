DROP TABLE IF EXISTS carto.surface_eau CASCADE;

CREATE TABLE carto.surface_eau AS
WITH
eau AS (
	SELECT b.gid as cid, (st_dump(st_union(st_intersection(a.geom, b.geom)))).geom as geom
	FROM bdt.bdt_surface_eau a
	     INNER JOIN ind.grid_10km_m b ON st_intersects(a.geom, b.geom)
	WHERE a.regime = 'Permanent'
	GROUP BY b.gid
)
SELECT row_number() over() as gid, cid, geom
FROM eau;
