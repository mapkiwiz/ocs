CREATE SCHEMA ocsv2;

CREATE TYPE ocsv2.ocs_nature AS ENUM (
    'AUTRE/?',
    'A/VIGNE', -- 221
    'A/PRAIRIE', -- 23
    'A/AGRICOLE', -- 21
    'A/ZONE_HUMIDE', -- 41,42
    'A/ESP.VERTS', -- 14
    'A/ARTIFICIALISE', -- 12, 13
    'A/NATUREL', -- 321, 322, 323, 5x
    'A/FORET', -- 31
    'ROCHERS', -- 33
    'NEIGE', -- 335
    'PERIURBAIN', -- 112
    'NATUREL', 
    'ARBORICULTURE', -- 22
    'VIGNE', -- 221
    'PRAIRIE', -- 231
    'CULTURES', -- 21
    'BATI', -- 111
    'FORET', -- 31
    'EAU', -- 51
    'AUTRE/INFRA', -- 122
    'INFRA' -- 122
);

CREATE TABLE ocsv2.ocsol (
    gid serial PRIMARY KEY,
    tileid integer,
    geom geometry(Polygon, 2154),
    nature ocsv2.ocs_nature
);

CREATE INDEX ocsol_geom_idx
ON ocsv2.ocsol USING GIST (geom);

CREATE TABLE ocsv2.simplified (
    gid serial PRIMARY KEY,
    tileid integer,
    geom geometry(Polygon, 2154),
    nature ocsv2.ocs_nature
);

CREATE INDEX simplified_geom_idx
ON ocsv2.simplified USING GIST (geom);

CREATE TABLE ocsv2.carto_clc (
    gid serial PRIMARY KEY,
    tileid integer,
    geom geometry(Polygon, 2154),
    nature ocsv2.ocs_nature,
    code_clc character(3)
);

CREATE INDEX carto_clc_geom_idx
ON ocsv2.carto_clc USING GIST (geom);

CREATE TABLE ocsv2.nature_clc (
    nature ocsv2.ocs_nature,
    code_clc character(3)
);

\COPY ocsv2.nature_clc FROM 'ocs_nature_code_clc.csv' WITH CSV HEADER;

CREATE TABLE ocsv2.code_clc (
    code_clc character(3),
    nature ocsv2.ocs_nature
);

\COPY ocsv2.code_clc FROM 'code_clc_ocs_nature.csv' WITH CSV HEADER;