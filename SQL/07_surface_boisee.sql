DROP TABLE IF EXISTS carto.surface_boisee CASCADE;

CREATE TABLE carto.surface_boisee AS
WITH
foret AS (
	SELECT g.gid as cid, (st_dump(st_intersection(g.geom, r.geom))).geom AS geom
	FROM ind.grid_10km_m g INNER JOIN bdt.bdt_zone_vegetation r ON st_intersects(g.geom, r.geom)
	WHERE  (   r.nature = 'Bois'
	           OR r.nature = 'Zone arborée'
	           OR r.nature LIKE 'Forêt fermée%' )
	      AND st_area(r.geom) > 1500
),
foret_na AS (
	SELECT b.cid, (st_dump(st_intersection(a.geom, b.geom))).geom
	FROM carto.surface_non_impermeable a INNER JOIN foret b
	     ON st_intersects(a.geom, b.geom)
)
SELECT row_number() over() AS gid, cid, geom
FROM foret_na;
