CREATE SCHEMA ocs;

CREATE TABLE ocs.grid_ocs (
    gid serial PRIMARY KEY,                                                                                      
    geom geometry(Polygon, 2154),
    dept character varying(30),
    geohash character varying(6),
    boundary boolean default false
);

CREATE INDEX grid_ocs_geom_idx
ON ocs.grid_ocs using gist (geom) ;

CREATE TYPE ocs_nature AS ENUM (
    'AUTRE/?', 
    'AUTRE/NATURE', 
    'AUTRE/ARTIFICIALISE', 
    'ARBORICULTURE',
    'VIGNE', 
    'PRAIRIE', 
    'CULTURES', 
    'BATI', 
    'FORET', 
    'EAU',
    'AUTRE/INFRA',
    'INFRA'
);

CREATE TABLE ocs.carto_raw (
    gid serial PRIMARY KEY,
    nature ocs_nature,
    area double precision,
    geom geometry(Polygon, 2154),
    tileid integer
);

CREATE INDEX carto_raw_geom_idx
ON ocs.carto_raw USING GIST (geom);

CREATE TABLE ocs.carto (
    gid serial PRIMARY KEY,
    nature ocs_nature,
    area double precision,
    geom geometry(Polygon, 2154),
    tileid integer
);

CREATE INDEX carto_geom_idx
ON ocs.carto USING GIST (geom);

CREATE TABLE ocs.carto_umc (
    gid serial PRIMARY KEY,
    nature ocs_nature,
    area double precision,
    geom geometry(Polygon, 2154),
    tileid integer
);

CREATE INDEX carto_umc_geom_idx
ON ocs.carto_umc USING GIST (geom);

CREATE TABLE ocs.autre_clc_cleaned (
    gid serial PRIMARY KEY,
    code_12 character(3),
    geom geometry(Polygon, 2154),
    tileid integer
);

CREATE INDEX autre_clc_cleaned_geom_idx
ON ocs.autre_clc_cleaned USING GIST (geom);

CREATE OR REPLACE VIEW ocs.autre_clc AS
SELECT b.code_12, a.tileid, (st_dump(st_intersection(b.geom, a.geom))).geom AS geom
FROM ocs.carto_umc a LEFT JOIN ref.clc_2012 b
     ON st_intersects(a.geom, b.geom)
WHERE a.nature IN ('AUTRE/NATURE', 'AUTRE/?')

CREATE TABLE ocs.carto_clc (
    gid serial PRIMARY KEY,
    tileid integer,
    geom geometry(Polygon, 2154),
    nature ocs_nature_clc,
    code_clc character(3)
);

CREATE INDEX carto_clc_geom_idx
ON ocs.carto_clc USING GIST (geom);

