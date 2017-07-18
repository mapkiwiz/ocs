INSERT INTO ocs.carto (tileid, nature, area, geom)
SELECT tileid, nature, st_area(geom) as area, geom
FROM ocsol;