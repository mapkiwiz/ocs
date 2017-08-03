-- DROP TABLE IF EXISTS carto.surface_boisee CASCADE;

CREATE VIEW aux.surface_boisee AS
SELECT geom FROM aux.surface_boisee_001
UNION ALL
SELECT geom FROM aux.surface_boisee_003
UNION ALL
SELECT geom FROM aux.surface_boisee_007
UNION ALL
SELECT geom FROM aux.surface_boisee_015
UNION ALL
SELECT geom FROM aux.surface_boisee_026
UNION ALL
SELECT geom FROM aux.surface_boisee_038
UNION ALL
SELECT geom FROM aux.surface_boisee_042
UNION ALL
SELECT geom FROM aux.surface_boisee_043
UNION ALL
SELECT geom FROM aux.surface_boisee_063
UNION ALL
SELECT geom FROM aux.surface_boisee_069
UNION ALL
SELECT geom FROM aux.surface_boisee_073
UNION ALL
SELECT geom FROM aux.surface_boisee_074;

CREATE TABLE aux.ecotone_foret AS
WITH
    boundary AS (
        SELECT (st_dump(st_boundary(geom))).geom
        FROM aux.surface_boisee
    )
SELECT row_number() over() as gid, geom
FROM boundary
WHERE ST_GeometryType(geom) = 'ST_LineString';

ALTER TABLE aux.ecotone_foret
ADD PRIMARY KEY (gid);

CREATE INDEX ecotone_foret_geom_idx
ON aux.ecotone_foret USING GIST (geom);