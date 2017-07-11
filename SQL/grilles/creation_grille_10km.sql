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