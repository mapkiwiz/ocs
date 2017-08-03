CREATE TABLE aux.sb_grid_500m_rel AS
SELECT a.fid AS sb_gid, b.gid AS grid_gid 
FROM aux.surface_boisee_with_attr a
INNER JOIN ind.grid_500m b
ON st_intersects(a.geom, b.geom);

CREATE TABLE ind_aura.conn_for AS
WITH
sb_cells AS (
	SELECT sb_gid, count(grid_gid) AS cnt
	FROM aux.sb_grid_500m_rel
	GROUP BY sb_gid
)
SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
FROM aux.sb_grid_500m_rel a
INNER JOIN sb_cells b
ON a.sb_gid = b.sb_gid
GROUP BY a.grid_gid;