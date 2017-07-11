CREATE TABLE carto.ecotone_foret AS
WITH
    boundary AS (
        SELECT (st_dump(st_boundary(geom))).geom
        FROM carto.surface_boisee
    )
SELECT row_number() over() as gid, geom
FROM boundary
WHERE ST_GeometryType(geom) = 'ST_LineString';

ALTER TABLE carto.ecotone_foret
ADD PRIMARY KEY (gid);

CREATE INDEX ecotone_foret_geom_idx
ON carto.ecotone_foret USING GIST (geom);