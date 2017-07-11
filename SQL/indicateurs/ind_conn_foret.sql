ALTER TABLE carto.surface_boisee
ADD COLUMN n_mailles int;

WITH
cnt AS (
    SELECT b.gid, count(a.gid) as cnt
    FROM ind.grid_500m a
         INNER JOIN carto.surface_boisee b ON st_intersects(a.geom, b.geom)
    WHERE a.dept = 'CANTAL'
    GROUP BY b.gid
)
UPDATE carto.surface_boisee
SET n_mailles = cnt.cnt
FROM cnt
WHERE surface_boisee.gid = cnt.gid;


