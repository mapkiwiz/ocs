DROP TABLE IF EXISTS carto.surface_construite CASCADE;

CREATE TABLE carto.surface_construite AS
WITH bati AS (
	SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_bati_indifferencie t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_bati_remarquable t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_bati_industriel t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_construction_legere t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_construction_lineaire t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_construction_surfacique t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_cimetiere t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_reservoir t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_terrain_sport t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_piste_aerodrome t
	UNION SELECT st_multi(st_buffer(t.geom, 25)) AS geom FROM bdt.bdt_surface_activite t
),
buffer as (
	SELECT (st_dump(st_buffer((st_dump(st_union(geom))).geom, -5))).geom as geom
	FROM bati
),
simple as (
	SELECT st_simplifyPreserveTopology(geom, 1) as geom
	FROM buffer
	WHERE st_geometrytype(geom) = 'ST_Polygon'
),
clip as (
	SELECT b.gid as cid, (st_dump(st_union(st_intersection(a.geom, b.geom)))).geom as geom
	FROM simple a INNER JOIN ind.grid_10km_m b ON st_intersects(a.geom, b.geom)
	GROUP BY b.gid
)
SELECT row_number() over() as gid, cid, geom
FROM clip ;

UPDATE carto.surface_construite
SET geom = removeHoles(geom, 2500);