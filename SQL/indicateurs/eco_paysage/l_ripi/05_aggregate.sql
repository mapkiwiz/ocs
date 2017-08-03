CREATE TABLE ind_aura.ripi_longueur AS
SELECT
	a.gid,
	COALESCE(sum(b.tx_for * st_length(b.geom)), 0) as l_ripi,
	(sum(b.tx_for * st_length(b.geom)) / sum(st_length(b.geom))) as t_ripi
FROM ind.grid_500m a LEFT JOIN
     ripi.lin_dgo b ON st_intersects(a.geom, b.geom)
-- WHERE a.tileid = 16
GROUP BY a.gid;