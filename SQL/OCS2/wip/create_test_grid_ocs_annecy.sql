insert into ocs.grid_ocs (geom)
select st_setsrid(st_makebox2d(st_makepoint(927e3, 6532e3), st_makepoint(937e3, 6542e3)), 2154) ;