CREATE TYPE ocsv2.ocs_nature AS ENUM (
    'AUTRE/?', 
    'PERIURBAIN',
    'NATUREL',
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

CREATE TYPE ocsv2.ocs_nature_clc AS ENUM (
    'A/NATUREL', -- 14,32x,5x
    'A/ZONE_HUMIDE', -- 41,42
    'A/VIGNE', -- 221
    'A/PRAIRIE', -- 23
    'A/AGRICOLE', -- 21
    'A/LOGISTIQUE', -- 12
    'A/CARRIERE', -- 13
    'A/LANDES', -- 322
    'A/PELOUSE', -- 321
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

CREATE TABLE ocsv2.carto_clc (
    gid serial PRIMARY KEY,
    tileid integer,
    geom geometry(Polygon, 2154),
    nature ocsv2.ocs_nature_clc,
    code_clc character(3)
);

CREATE INDEX carto_clc_geom_idx
ON ocsv2.carto_clc USING GIST (geom);