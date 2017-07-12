create schema ocs;

create table ocs.grid_ocs (
	gid serial,                                                                                      
	geom geometry(Polygon, 2154),
	dept character varying(30)
);

insert into ocs.grid_ocs (geom)
select st_setsrid(st_makebox2d(st_makepoint(927e3, 6532e3), st_makepoint(937e3, 6542e3)), 2154) ;