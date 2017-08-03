CREATE TABLE ind_aura.frayere AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_length(st_intersection(a.geom, b.geom))), 0) AS longueur
FROM ind.grid_500m a
     LEFT JOIN ref.frayere b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;

CREATE TABLE ind_aura.zone_humide AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_area(st_intersection(a.geom, b.geom))), 0) AS surface
FROM ind.grid_500m a
     LEFT JOIN ref.zone_humide b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;

CREATE TABLE ind_aura.foret_evol_nat AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_area(safe_intersection(a.geom, b.geom, 0.5))), 0) AS surface
FROM ind.grid_500m a
     LEFT JOIN ref.foret_evol_nat b
     ON safe_intersects(a.geom, b.geom, 0.5)
GROUP BY a.gid;

CREATE TABLE ind_aura.tourbiere AS
SELECT
	a.gid AS cid,
	COALESCE(sum(st_area(safe_intersection(a.geom, b.geom, 0.5))), 0) AS surface
FROM ind.grid_500m a
     LEFT JOIN ref.tourbiere b
     ON st_intersects(a.geom, b.geom)
GROUP BY a.gid;
