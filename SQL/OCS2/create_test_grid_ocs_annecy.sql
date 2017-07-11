create schema test;

create table test.grid_ocs (
gid serial,                                                                                      
geom geometry(Polygon, 2154),
dept character varying(30),
cx double precision,
cy double precision);

insert into test.grid_ocs (geom)
select st_setsrid(st_makebox2d(st_makepoint(937e3, 6532e3), st_makepoint(947e3, 6542e3)), 2154) ;