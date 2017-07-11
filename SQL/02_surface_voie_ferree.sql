DROP TABLE IF EXISTS carto.surface_voie_ferree CASCADE;

CREATE TABLE carto.surface_voie_ferree AS
WITH infra AS (
	SELECT g.gid as cid, g.dept, (st_dump(st_union(st_intersection(st_buffer(r.geom,
		CASE
			WHEN r.nature = 'LGV' THEN 15
			WHEN r.nature = 'Principale' AND r.nb_voies = 2 THEN 8
			ELSE 4
		END), g.geom)))).geom as geom
	FROM bdt.bdt_troncon_voie_ferree r inner join ind.grid_10km_m g on st_intersects(g.geom, r.geom)
	WHERE r.pos_sol = 0
	GROUP BY g.gid, g.dept
)
SELECT row_number() over() as gid, cid, dept, geom
FROM infra
WHERE st_geometryType(geom) = 'ST_Polygon';