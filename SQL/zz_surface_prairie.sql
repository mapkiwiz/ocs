-- Nettoyage préalable

with p as (                          
select gid, (st_dump(geom)).geom from ref.rpg_2012 ),
invalid as (select gid from p
where not st_isvalid(geom))
delete from ref.rpg_2012                                                         
using invalid                                                
where rpg_2012.gid = invalid.gid ;


CREATE TABLE carto.surface_prairie AS
WITH
prairie AS (
	SELECT a.gid as cid, (st_dump(st_intersection(a.geom, b.geom))).geom AS geom
	FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
	WHERE b.cult_maj = 17 or b.cult_maj = 18
)
SELECT row_number() over() as gid, cid, geom
FROM prairie;

CREATE TABLE carto.surface_cultures AS
WITH
cultures AS (
	SELECT a.gid as cid, (st_dump(st_intersection(a.geom, b.geom))).geom AS geom
	FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
	WHERE b.cult_maj NOT IN (17,18,20,21,22,23,27)
)
SELECT row_number() over() as gid, cid, geom
FROM cultures;

CREATE TABLE carto.surface_arboriculture AS
WITH
arboriculture AS (
	SELECT a.gid as cid, (st_dump(st_intersection(a.geom, b.geom))).geom AS geom
	FROM ind.grid_10km_m a INNER JOIN ref.rpg_2012 b ON st_intersects(a.geom, b.geom)
	WHERE b.cult_maj IN (20,21,22,23,27)
)
SELECT row_number() over() as gid, cid, geom
FROM arboriculture;