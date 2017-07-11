DROP TABLE IF EXISTS carto.surface_route CASCADE;

CREATE TABLE carto.surface_route AS
WITH infra AS (
	SELECT g.gid as cid, g.dept, (st_dump(st_union(st_intersection(st_buffer(r.geom, r.largeur/2 + 2), g.geom)))).geom as geom
	FROM bdt.bdt_route r inner join ind.grid_10km_m g on st_intersects(g.geom, r.geom)
	WHERE r.nature NOT IN ('Sentier', 'Escalier', 'Chemin') AND pos_sol = 0
	GROUP BY g.gid, g.dept
)
SELECT row_number() over() as gid, cid, dept, geom
FROM infra
WHERE st_geometryType(geom) = 'ST_Polygon';