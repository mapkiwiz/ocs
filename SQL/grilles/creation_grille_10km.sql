CREATE TABLE ind.grid_10km AS
WITH cell AS (
	SELECT dept, floor(eoforigin/10000) as cx, floor(noforigin/10000) as cy, st_union(geom) as geom
	FROM ind.grid_500m_laea
	GROUP BY dept, floor(eoforigin/10000), floor(noforigin/10000)
),
subcell AS (
	SELECT dept, cx, cy, (st_dump(geom)).geom as geom
	FROM cell
)
SELECT row_number() over() AS gid, dept, cx, cy, geom
FROM subcell;

ALTER TABLE ind.grid_10km 
ADD PRIMARY KEY (gid) ;

CREATE INDEX grid_10km_geom_idx
ON ind.grid_10km USING GIST (geom) ;


ALTER TABLE ind.grid_500m
ADD COLUMN gid_10k bigint;

CREATE INDEX grid_500m_gid_10k_idx
ON ind.grid_500m (gid_10k) ;

WITH
match AS (
    SELECT a.gid as gid_10k, b.gid
    FROM ind.grid_10km_m a INNER JOIN ind.grid_500m b ON st_contains(a.geom, st_centroid(b.geom))
)
UPDATE ind.grid_500m
SET gid_10k = match.gid_10k
FROM match
WHERE grid_500m.gid = match.gid;

WITH
match AS (
    SELECT b.gid, a.gid as tileid, a.dept
    FROM ocs.grid_ocs a INNER JOIN ind.grid_500m b ON st_contains(a.geom, st_centroid(b.geom))
)
UPDATE ind.grid_500m
SET
	tileid = match.tileid,
	dept = match.dept
FROM match
WHERE grid_500m.gid = match.gid;

WITH
near AS (
    SELECT a.gid, b.gid AS tileid, b.dept, row_number() over(PARTITION BY a.gid) AS rank
    FROM ind.grid_500m a
         INNER JOIN ocs.grid_ocs b ON b.geom && a.geom
    WHERE a.tileid IS NULL
    ORDER BY st_distance(a.geom, b.geom)
),
-- rank AS (
--     SELECT cid, pays_id, row_number() over(PARTITION BY cid) AS rank
--     FROM near
--     GROUP BY cid
-- ),
nearest AS (
    SELECT gid, tileid, dept
    FROM near
    WHERE rank = 1
)
UPDATE ind.grid_500m
SET
	tileid = nearest.tileid,
	dept = nearest.dept
FROM nearest
WHERE grid_500m.gid = nearest.gid;

WITH outside AS (
	SELECT a.gid, b.gid AS bdt_gid
	FROM ind.grid_500m a LEFT JOIN
	     bdt.bdt_commune b ON st_intersects(a.geom, b.geom)
	WHERE b.gid IS NULL
)
DELETE FROM ind.grid_500m
USING outside
WHERE grid_500m.gid = outside.gid;