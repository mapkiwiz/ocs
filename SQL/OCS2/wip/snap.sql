ALTER TABLE surf_foret_nino
ADD COLUMN target bigint;

WITH spatial_join AS (
	SELECT a.gid, b.gid AS target
	FROM surf_foret_nino a LEFT JOIN
	     surf_nino b ON st_contains(b.geom, st_pointonsurface(a.geom))
)
UPDATE surf_foret_nino
SET target = spatial_join.target
FROM spatial_join
WHERE surf_foret_nino.gid = spatial_join.gid;

--

CREATE TABLE nino_l AS
SELECT gid, st_boundary(geom) AS geom
FROM surf_nino;

CREATE INDEX nino_l_gid_idx
ON nino_l (gid);

CREATE INDEX nino_l_geom_idx
ON nino_l USING GIST (geom);

CREATE TABLE foret_l AS
WITH segments AS (
	SELECT gid AS polygon_id, disaggregate((st_dump(st_boundary(geom))).geom, 5) AS geom
	FROM surf_foret_nino
)
SELECT row_number() over() AS gid, polygon_id, geom
FROM segments ;

ALTER TABLE foret_l
ADD COLUMN dist_infra double precision;

-- pour chaque paire polygone / cible
-- uniquement pour les polygones plus grands que l'UMC

WITH dist AS (
	SELECT a.gid, min(st_distance(st_centroid(a.geom), (SELECT geom FROM nino_l WHERE gid = 8))) as measure
	FROM foret_l a
	WHERE polygon_id = 39
	GROUP BY a.gid
)
UPDATE foret_l
SET dist_infra = dist.measure
FROM dist
WHERE foret_l.gid = dist.gid;


CREATE TABLE foret_buf AS
WITH
near AS (
	SELECT geom, dist_infra
	FROM foret_l
	WHERE polygon_id = 39 AND dist_infra <= 5
),
buf AS (
	SELECT (st_dump(st_union(st_buffer(geom, 2*dist_infra)))).geom
	FROM near
)
SELECT geom FROM buf
WHERE st_area(geom) > 200;

CREATE TABLE foret_snapped AS
WITH
j AS (
	SELECT geom
	FROM surf_foret_nino
	WHERE gid = 39
	UNION ALL
	SELECT geom
	FROM foret_buf
),
u AS (
	SELECT (st_dump(st_union(geom))).geom
	FROM j
),
clip AS (
	-- si TopologyException, ajouter les polygones de u un par un ?
	SELECT (st_dump(coalesce(st_intersection(u.geom, b.geom), u.geom))).geom
	FROM u LEFT JOIN surf_nino b ON st_intersects(u.geom, b.geom)
	WHERE b.gid = 8
)
SELECT geom FROM clip
ORDER BY st_area(geom) DESC
LIMIT 1;

-- Alternative avec ST_Snap

CREATE TABLE foret_snapped2 AS
SELECT st_snap((SELECT geom FROM surf_foret_nino WHERE gid = 39), (SELECT geom FROM surf_nino WHERE gid = 8), 5) AS geom;

CREATE TABLE foret_ext_ring AS
WITH
near AS (
	SELECT geom, CASE WHEN dist_infra <= 5 THEN 2*dist_infra ELSE 0 END AS bdist
	FROM foret_l
	WHERE polygon_id = 39
),
buf AS (
	SELECT (st_dump(st_union(st_buffer(geom, bdist)))).geom
	FROM near
)
SELECT geom FROM buf;

-- SnapPolygons Tests

CREATE TABLE foret_snapped_ AS
SELECT SnapPolygons(
	(SELECT geom FROM surf_foret_nino WHERE gid = 39),
	(SELECT geom FROM surf_nino WHERE gid = 8),
	5) AS geom;

CREATE TABLE foret_snapped_ AS
SELECT SnapPolygons(a.geom, b.geom, 5) AS geom
FROM surf_foret_nino a INNER JOIN surf_nino b
     ON a.target = b.gid;

CREATE TABLE foret_snapped_ AS
SELECT SnapPolygonsWithFallback(a.geom, b.geom, 5) AS geom
FROM surf_foret_nino a INNER JOIN surf_nino b
     ON a.target = b.gid
WHERE st_area(a.geom) > 2500;