CREATE OR REPLACE FUNCTION ind.dgo_bdt_cde_surf(cell_id bigint, disagg_step double precision)
RETURNS SETOF geometry(LineString)
AS
$func$
DECLARE
BEGIN

    DROP TABLE IF EXISTS ripi_lin_points;
    DROP TABLE IF EXISTS ripi_voronoi;
    DROP TABLE IF EXISTS ripi_dgo;
    DROP TABLE IF EXISTS ripi_lin_dgo;
    DROP TABLE IF EXISTS ripi_dgo_side;

    -- RAISE NOTICE 'Create DGOs';

    CREATE TEMP TABLE ripi_lin_points as
    WITH
    lines AS (
        SELECT geom
        FROM st_dump(st_simplify((SELECT st_union(geom) FROM ripi.lin_by_grid WHERE cid = cell_id), 1.0))
    )
    SELECT (disaggregate_line(geom, disagg_step)).vertex as geom
    FROM lines;

    CREATE TABLE ripi_voronoi AS
    SELECT geom
    FROM st_dump(st_voronoipolygons((SELECT st_union(st_force2d(geom)) FROM ripi_lin_points), 2.5));

    CREATE TABLE ripi_dgo AS
    WITH ugo AS (
        SELECT (st_dump(st_intersection(a.geom, b.geom))).geom
        FROM ripi_voronoi a, ripi.cde_buffer_5m b
        WHERE st_isvalid(a.geom) 
              AND st_intersects(a.geom, b.geom)
              AND b.cid = cell_id
    )
    SELECT row_number() over() as dgo_id, geom
    FROM ugo;

    CREATE TABLE ripi_lin_dgo AS
    WITH
    lines AS (
        SELECT (st_dump(geom)).geom
        FROM ripi.lin_by_grid
        WHERE cid = cell_id
    )
    SELECT b.dgo_id, st_force2d(st_intersection(a.geom, b.geom)) as geom
    FROM lines a, ripi_dgo b
    WHERE st_intersects(a.geom, b.geom);

    RETURN QUERY
    WITH
    lines AS (
        SELECT (st_dump(geom)).geom
        FROM ripi.lin_by_grid
        WHERE cid = cell_id
    ),
    split AS (
        SELECT a.dgo_id, (st_dump(st_split(a.geom, b.geom))).geom
        FROM ripi_dgo a, lines b
        WHERE st_intersects(a.geom, b.geom)
    )
    SELECT st_force2d(geom) as geom
    FROM split;

END
$func$
LANGUAGE plpgsql VOLATILE STRICT;