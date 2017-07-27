CREATE TABLE ocsv2.random_controls (
	gid serial PRIMARY KEY,
	dept text,
	nature ocsv2.ocs_nature,
	tileid integer
);

\COPY ocsv2.random_controls (dept, nature, tileid) FROM 'random_controls.csv' WITH CSV HEADER;

ALTER TABLE ocsv2.random_controls
ADD COLUMN geom geometry(Polygon, 2154);

UPDATE ocsv2.random_controls
SET geom = grid_ocs.geom
FROM ocs.grid_ocs
WHERE random_controls.tileid = grid_ocs.gid;