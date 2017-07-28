SELECT
	((SELECT st_area(geom) FROM grid_ocs WHERE gid = 1) - sum(st_area(geom))) / 1e4 AS tile_diff_ha
FROM simplified;

SELECT
	((SELECT st_area(geom) FROM grid_ocs WHERE gid = 1) - sum(st_area(geom))) / 1e4 AS tile_diff_ha
FROM carto_clc ;

SELECT nature,
       sum(st_area(geom)) / 1e4 as ha,
       to_char(100 * sum(st_area(geom)) / (SELECT st_area(geom) FROM grid_ocs WHERE gid = 1), '990.0 %') AS prop
FROM carto_clc
GROUP BY nature
ORDER BY nature DESC ;


SELECT
     b.gid, (st_area(b.geom) - sum(st_area(a.geom))) / 1e4 AS tile_diff_ha
FROM ocsv2.carto_clc a INNER JOIN ocs.grid_ocs b
     ON a.tileid = b.gid
GROUP BY b.gid
ORDER BY tile_diff_ha DESC;