	DELETE FROM ocsv2.simplified
	WHERE tileid = (SELECT tileid FROM grid_ocs WHERE gid = 1);

	INSERT INTO ocsv2.simplified (tileid, geom, nature)
	SELECT
		(SELECT tileid FROM grid_ocs WHERE gid = 1) AS tileid,
		geom,
		trim(nature)::ocsv2.ocs_nature
	FROM simplified;

	DELETE FROM ocsv2.carto_clc
	WHERE tileid = (SELECT tileid FROM grid_ocs WHERE gid = 1);

	INSERT INTO ocsv2.carto_clc (tileid, geom, nature, code_clc)
	SELECT
		(SELECT tileid FROM grid_ocs WHERE gid = 1) AS tileid,
		geom,
		nature,
		code_clc
	FROM carto_clc;