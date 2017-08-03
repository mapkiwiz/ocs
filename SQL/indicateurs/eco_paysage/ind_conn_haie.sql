CREATE TABLE aux.haie_grid_500m_rel AS
SELECT a.gid AS haie_gid, b.gid AS grid_gid 
FROM bdt.bdt_zone_vegetation a
INNER JOIN ind.grid_500m b
ON st_intersects(a.geom, b.geom)
WHERE a.nature = 'Haie';

CREATE TABLE ind_aura.conn_haie AS
WITH
haie_cells AS (
	SELECT haie_gid, count(grid_gid) AS cnt
	FROM aux.haie_grid_500m_rel
	GROUP BY haie_gid
)
SELECT a.grid_gid AS cid, max(b.cnt) AS cnt
FROM aux.haie_grid_500m_rel a
INNER JOIN haie_cells b
ON a.haie_gid = b.haie_gid
GROUP BY a.grid_gid;