CREATE SCHEMA ocs;

CREATE TYPE ocs_nature AS ENUM (
    'AUTRE/?', 
    'AUTRE/NATURE', 
    'AUTRE/BATI', 
    'ARBO', 
    'PRAIRIE', 
    'CULTURES', 
    'BATI', 
    'FORET', 
    'EAU',
    'INFRA');

-- Ajouter :
-- VIGNE
-- AUTRE/INFRA

CREATE TABLE ocs.carto (
    gid serial,
    nature ocs_nature,
    area double precision,
    geom geometry(Polygon, 2154),
    cell integer
);

CREATE SEQUENCE ocs.carto_cell_seq;


