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
