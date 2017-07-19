DROP TABLE IF EXISTS ocs.grid_ocs_boundary;

CREATE TABLE ocs.grid_ocs_boundary AS
WITH clip AS (
  SELECT a.gid, a.dept AS dept, st_intersection(a.geom, st_union(b.geom)) AS geom
  FROM ocs.grid_ocs a LEFT JOIN bdt.bdt_commune b ON st_intersects(a.geom, b.geom)
  WHERE a.boundary AND a.dept = 'ISERE'
  GROUP BY a.gid
),
parts AS (
  SELECT gid, dept, (st_dump(geom)).geom
  FROM clip
)
SELECT gid, geom, dept
FROM parts;

WITH
ut AS (
	SELECT a.gid
	FROM ocs.grid_ocs_boundary a
	GROUP BY a.gid
	HAVING count(a.gid) = 1
),
geoms aS (
	SELECT a.gid, a.geom
	FROM ocs.grid_ocs_boundary a
	WHERE EXISTS (
		SELECT gid FROM ut
		WHERE gid = ut.gid
	)
)
UPDATE ocs.grid_ocs
SET geom = geoms.geom
FROM geoms
WHERE grid_ocs.gid = geoms.gid;

WITH
ut AS (
	SELECT a.gid
	FROM ocs.grid_ocs_boundary a
	GROUP BY a.gid
	HAVING count(a.gid) > 1
)
DELETE FROM ocs.grid_ocs
USING ut
WHERE grid_ocs.gid = ut.gid;

WITH
ut AS (
	SELECT a.gid
	FROM ocs.grid_ocs_boundary a
	GROUP BY a.gid
	HAVING count(a.gid) > 1
),
geoms aS (
	SELECT a.gid, a.dept, a.geom
	FROM ocs.grid_ocs_boundary a
	WHERE EXISTS (
		SELECT gid FROM ut
		WHERE gid = a.gid
	)
)
INSERT INTO ocs.grid_ocs (gid, dept, geom)
SELECT row_number() over() + (SELECT max(gid) FROM ocs.grid_ocs) AS gid,
dept, geom
FROM geoms;