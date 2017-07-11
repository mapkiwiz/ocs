CREATE TABLE carto.tache_urbaine_20m (
	gid serial primary key,
	geom geometry(Polygon, 2154)
);

WITH bati AS (
	SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_bati_indifferencie t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_bati_remarquable t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_bati_industriel t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_bati_remarquable t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_construction_legere t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_construction_lineaire t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_construction_surfacique t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_cimetiere t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_reservoir t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_terrain_sport t
	UNION SELECT st_multi(st_buffer(t.geom, 20)) AS geom FROM bdt.bdt_piste_aerodrome t
),
buffer as (
	SELECT (st_dump(st_buffer((st_dump(st_union(geom))).geom, -20))).geom as geom
	FROM bati
)
INSERT INTO carto.tache_urbaine_20m (geom)
SELECT st_simplifyPreserveTopology(geom, 1) FROM buffer
WHERE st_geometrytype(geom) = 'ST_Polygon' ;

UPDATE carto.tache_urbaine_20m
SET geom = removeHoles(geom, 250);