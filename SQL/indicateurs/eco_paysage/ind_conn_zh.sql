CREATE TABLE aux.zh_grid_500m_rel AS
SELECT a.gid AS zh_gid, b.gid AS grid_gid 
FROM ref.zone_humide a
INNER JOIN ind.grid_500m b
ON st_intersects(a.geom, b.geom);

CREATE TABLE ind_aura.conn_zh AS
WITH
zh_cells AS (
	SELECT zh_gid, count(grid_gid) AS cnt
	FROM aux.zh_grid_500m_rel
	GROUP BY zh_gid
)
SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
FROM aux.zh_grid_500m_rel a
INNER JOIN zh_cells b
ON a.zh_gid = b.zh_gid
GROUP BY a.grid_gid;