DROP TABLE IF EXISTS carto.surface_urbanisee CASCADE;

CREATE TABLE carto.surface_urbanisee AS
WITH
urbanisee AS (
	SELECT g.gid, r.geom as geom
	FROM ind.grid_10km_m g INNER JOIN carto.surface_route r ON g.gid = r.cid
	UNION
	SELECT g.gid, r.geom as geom
	FROM ind.grid_10km_m g INNER JOIN carto.surface_voie_ferree r ON g.gid = r.cid
	UNION
	SELECT g.gid, r.geom as geom
	FROM ind.grid_10km_m g INNER JOIN carto.surface_construite r ON g.gid = r.cid
),
union_urbanisee AS (
	SELECT gid, st_union(geom) as geom
	FROM urbanisee
	GROUP BY gid
),
dump AS (
	SELECT g.gid as cid, (st_dump(st_intersection(u.geom, g.geom))).geom
	FROM union_urbanisee u INNER JOIN ind.grid_10km_m g ON u.gid = g.gid
)
SELECT row_number() over() as gid, cid, geom
FROM dump;

UPDATE carto.surface_urbanisee
SET geom = removeHoles(geom, 2500);