-- l_route1
-- Longueur de routes principales

CREATE TABLE ind_aura.route1 AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_length(st_intersection(a.geom, b.geom))), 0) AS longueur
FROM ind.grid_500m a
     LEFT JOIN bdt.bdt_route_primaire b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;

-- l_route2
-- Longueur de routes secondaires

CREATE TABLE ind_aura.route2 AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_length(st_intersection(a.geom, b.geom))), 0) AS longueur
FROM ind.grid_500m a
     LEFT JOIN bdt.bdt_route_secondaire b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;

-- l_elect
-- Longueur de ligne électrique

CREATE TABLE ind_aura.ligne_electrique AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_length(st_intersection(a.geom, b.geom))), 0) AS longueur
FROM ind.grid_500m a
     LEFT JOIN bdt.bdt_ligne_electrique b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;