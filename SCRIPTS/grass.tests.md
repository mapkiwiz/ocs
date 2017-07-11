v.clean -c --overwrite input=carto_patch_306@cantal output=carto_patch_306_cleaned type=line,boundary,area tool=snap,break,bpol,rmdangle,rmsa,rmdupl thres=1.5,1.00,1.00,1.00,1.00

v.overlay --overwrite ainput=grid_10km_306@cantal atype=area binput=carto_surface_agricole_306@cantal operator=not output=carto_surface_non_agricole_306 snap=2.5

v.patch -n --overwrite --verbose input=carto_surface_agricole_306@cantal,carto_surface_boisee_306@cantal,carto_surface_eau_306@cantal,carto_surface_construire_306@cantal output=carto_patch_306

v.in.ogr input=PG:dbname=fdca layer=ind.grid_10km_m where="gid=306" snap=-1 output=grid_10km_306

v.in.ogr input=PG:dbname=fdca layer=carto.surface_agricole where="cid=306" snap=0.001 output=surface_agricole_306
c.clean -c --overwrite input=surface_agricole_306@cantal output=surface_agricole_ok tool=snap,break,bpol,rmdangle,rmsa,rmdupl,rmarea thres=5,1,1,1,1,1,500