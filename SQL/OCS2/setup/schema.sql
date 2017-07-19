CREATE SCHEMA ocs;

CREATE TABLE ocs.grid_ocs (
    gid serial PRIMARY KEY,                                                                                      
    geom geometry(Polygon, 2154),
    dept character varying(30),
    geohash character varying(6),
    boundary boolean default false
);

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

