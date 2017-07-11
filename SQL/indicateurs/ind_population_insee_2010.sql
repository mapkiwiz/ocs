ALTER TABLE ind.grid_500m
ADD COLUMN pop_2010 double precision default 0.0;

WITH agg AS (
	SELECT g.gid, sum(p.pop) as pop
	FROM ind.grid_500m g INNER JOIN ref.insee_pop_2010_200m_v p
	     ON st_contains(g.geom, p.geom)
	GROUP BY g.gid
)
UPDATE ind.grid_500m
SET pop_2010 = agg.pop
FROM agg
WHERE grid_500m.gid = agg.gid;