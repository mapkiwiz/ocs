DELETE FROM ocsv2.ocsol
WHERE tileid = (SELECT tileid FROM grid_ocs WHERE gid = 1);

INSERT INTO ocsv2.ocsol (tileid, geom, nature)
SELECT
	(SELECT tileid FROM grid_ocs WHERE gid = 1) AS tileid,
	geom,
	nature::ocsv2.ocs_nature
FROM ocsol
WHERE ST_GeometryType(geom) = 'ST_Polygon';