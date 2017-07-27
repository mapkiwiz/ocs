CREATE TABLE ocs.tile_majority_nature AS
WITH
agg AS (
    SELECT a.tileid, a.nature, sum(st_area(a.geom)) / 1e4 as surf_ha
    FROM ocs.carto_clc a
    GROUP BY a.tileid, a.nature
    ORDER BY tileid, surf_ha DESC
),
rank AS (
    SELECT tileid, nature, surf_ha, row_number() over(PARTITION BY tileid) AS surf_rank
    FROM agg
)
SELECT  tileid, nature, surf_ha, surf_rank
FROM rank
WHERE surf_rank <= 2;

WITH random_tiles AS (
    SELECT b.dept, a.tileid, a.nature
    FROM ocs.tile_majority_nature a INNER JOIN ocs.grid_ocs b
         ON a.tileid = b.gid
    WHERE a.surf_rank = 1 AND a.surf_ha >= 2500
    ORDER BY random()
),
ranked AS (
    SELECT dept, nature, tileid, row_number() over(PARTITION BY dept, nature) AS rank
    FROM random_tiles
)
SELECT dept, nature, tileid
FROM ranked
WHERE rank = 1
  AND nature IN ('FORET', 'CULTURES', 'PRAIRIE', 'VIGNE')
  AND dept NOT IN ('CANTAL', 'SAVOIE', 'HAUTE-SAVOIE');