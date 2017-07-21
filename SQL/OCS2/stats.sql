WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_raw a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
smalls AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_raw a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    WHERE st_area(a.geom) < 2500
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept,
       a.nobj, c.nobj AS nsmall,
       (c.nobj::numeric / a.nobj::numeric) * 100.0 AS small_ratio,
       b.tile_area,
       a.obj_area, c.obj_area AS small_area,
       (c.obj_area / a.obj_area) * 100.0 AS small_area_ratio,
       100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM depts b
     LEFT JOIN objs a ON a.dept = b.dept
     LEFT JOIN smalls c ON c.dept = b.dept
ORDER BY b.dept;

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept, a.nobj, a.obj_area, b.tile_area, 100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM objs a RIGHT JOIN depts b ON a.dept = b.dept
ORDER BY b.dept;

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept, a.nobj, a.obj_area, b.tile_area, 100.0 * (a.obj_area / b.tile_area) - 100.0 AS overlap
FROM objs a RIGHT JOIN depts b ON a.dept = b.dept
ORDER BY b.dept;

WITH
objs AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    GROUP BY b.dept
),
autres AS (
    SELECT b.dept, count(a.gid) AS nobj, sum(st_area(a.geom)) / 1e7 AS obj_area
    FROM ocs.carto_umc a INNER JOIN ocs.grid_ocs b ON b.gid = a.tileid
    WHERE a.nature IN ('AUTRE/NATURE'::ocs_nature, 'AUTRE/?'::ocs_nature)
    GROUP BY b.dept
),
depts AS (
    SELECT dept, sum(st_area(geom)) / 1e7 AS tile_area
    FROM ocs.grid_ocs
    GROUP BY dept
)
SELECT b.dept,
       a.nobj, c.nobj AS nautre, (c.nobj::numeric / a.nobj::numeric) * 100.0 AS npautre,
       b.tile_area, c.obj_area AS autre_area, (c.obj_area / b.tile_area) * 100.0 AS pautre
FROM depts b
     LEFT JOIN objs a ON a.dept = b.dept
     LEFT JOIN autres c ON c.dept = b.dept
ORDER BY b.dept;