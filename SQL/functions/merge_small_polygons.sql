-- Merge small polygons to neighbor sharing largest boundary
--
CREATE OR REPLACE FUNCTION merge_small_polygons(source_table text, destination_table text, type_attr text default 'type', max_area double precision default 2500, target_schema text default 'public')
RETURNS integer
AS
$func$
DECLARE

    smallp RECORD;
    p geometry;
    u geometry;
    feature RECORD;
    target RECORD;
    processed integer default 0;
    len double precision;
    max_len double precision;
    matched boolean;
    unmatched integer default 0;

BEGIN

    EXECUTE 'CREATE TEMP TABLE _bigger AS SELECT gid, ' || quote_ident(type_attr) || ' as type, geom FROM ' || quote_ident(target_schema) || '.' || quote_ident(source_table) || ' WHERE st_area(geom) >= ' || max_area ;
    EXECUTE 'CREATE TEMP TABLE _smaller AS SELECT gid, ' || quote_ident(type_attr) || ' as type, geom FROM ' || quote_ident(target_schema) || '.' || quote_ident(source_table) || ' WHERE st_area(geom) < ' || max_area ;
    CREATE TEMP TABLE _unmatched AS SELECT * FROM _smaller WITH NO DATA;
    CREATE INDEX _bigger_geom_idx ON _bigger USING GIST (geom);
    CREATE SEQUENCE _bigger_gid_seq ;
    ALTER TABLE _bigger ALTER COLUMN gid SET DEFAULT nextval('_bigger_gid_seq'::regclass);
    PERFORM setval('_bigger_gid_seq'::regclass, (SELECT max(gid) FROM _bigger));

    FOR smallp IN SELECT gid, geom, type FROM _smaller WHERE st_geometryType(geom) = 'ST_Polygon'
    LOOP
        p := smallp.geom;
        max_len := 0;
        target := NULL;
        matched := false;
        FOR feature IN SELECT * FROM _bigger WHERE st_intersects(_bigger.geom, p) AND _bigger.type = smallp.type
        LOOP
            len := st_length(st_intersection(feature.geom, p));
            IF len > max_len THEN
                max_len := len;
                target := feature;
                matched := true;
            END IF;
        END LOOP;
        IF matched THEN
            u := st_union(p, target.geom);
            IF st_geometryType(u) = 'ST_Polygon' THEN
                UPDATE _bigger SET geom = u WHERE gid = target.gid;
            ELSE
                INSERT INTO _unmatched (gid, geom, type) VALUES (smallp.gid, smallp.geom, target.type);
            END IF;
        ELSE
            INSERT INTO _unmatched (gid, geom, type) VALUES (smallp.gid, smallp.geom, smallp.type);
            unmatched := unmatched + 1;
        END IF;
        processed := processed + 1;
    END LOOP;

    INSERT INTO _bigger (type, geom) SELECT type, geom FROM _unmatched;
    EXECUTE 'CREATE TABLE ' || quote_ident(target_schema) || '.' || quote_ident(destination_table) || ' AS SELECT gid, type as ' || quote_ident(type_attr) || ', geom FROM _bigger ';

    DROP TABLE _bigger CASCADE ;
    DROP SEQUENCE _bigger_gid_seq;
    DROP TABLE _smaller CASCADE ;
    DROP TABLE _unmatched CASCADE;

    RAISE NOTICE '% unmatched polygons', unmatched;
    RETURN processed;

END
$func$
LANGUAGE plpgsql;