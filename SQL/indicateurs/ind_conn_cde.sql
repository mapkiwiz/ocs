CREATE TABLE ref.bdc_cde_topo_015 as
SELECT a.* from ref.bdc_cours_eau_2014 a
WHERE st_intersects(a.geom, (SELECT geom FROM ind.dept_ta WHERE dept = 'CANTAL'));

ALTER TABLE ref.bdc_cde_topo_015
ADD PRIMARY KEY (gid) ;

CREATE INDEX bdc_cde_topo_015_geom_idx
ON ref.bdc_cde_topo_015 USING GIST (geom);

SELECT topology.AddTopoGeometryColumn('bdc_cde_topo', 'ref', 'bdc_cde_topo_015', 'topo_geom', 'LINESTRING') ;

UPDATE ref.bdc_cde_topo_015  
SET topo_geom = topology.toTopoGeom(st_force2d(geom), 'bdc_cde_topo', 2, 1.0);

CREATE TABLE ref.bdc_roe_topo_015 as
SELECT a.* from ref.bdc_roe a
WHERE st_intersects(a.geom, (SELECT geom FROM ind.dept_ta WHERE dept = 'CANTAL'));

ALTER TABLE ref.bdc_roe_topo_015
ADD PRIMARY KEY (gid) ;

CREATE INDEX bdc_roe_topo_015_geom_idx
ON ref.bdc_roe_topo_015 USING GIST (geom);

SELECT topology.AddTopoGeometryColumn('bdc_cde_topo', 'ref', 'bdc_roe_topo_015', 'topo_geom', 'POINT') ;

UPDATE ref.bdc_roe_topo_015  
SET topo_geom = topology.toTopoGeom(st_force2d(geom), 'bdc_cde_topo', 3, 1.0);

-- Récupérer les sources et les exutoires

CREATE TABLE ref.bdc_cde_015_end_node AS
WITH cnt as (
    SELECT start_node as node_id, count(*)
    FROM bdc_cde_topo.edge GROUP BY start_node
    UNION ALL SELECT end_node as node_id, count(*)
    FROM bdc_cde_topo.edge GROUP BY  end_node),
nodes AS (
    SELECT node_id, sum(count) AS count FROM cnt
    GROUP BY node_id
    HAVING sum(count) < 2)
SELECT a.*, b.count
FROM bdc_cde_topo.node a, nodes b
WHERE a.node_id = b.node_id;

-- Exporter la liste des noeuds du ROE dans un fichir CSV

psql -A -F " " -t > 015_bdc_cde_roe.nodes <<EOF
SELECT DISTINCT a.node_id
FROM bdc_cde_topo.node a INNER JOIN bdc_cde_topo.relation b ON a.node_id = b.element_id
WHERE b.element_type = 1 -- POINT
      AND b.layer_id = 3 -- ref.bdc_roe_015
      AND EXISTS (
        SELECT edge_id FROM bdc_cde_topo.edge WHERE start_node = a.node_id or end_node = a.node_id
      ); 
EOF


-- Exporter la liste des arêtes dans un fichier CSV

psql -A -F " " -t > 015_bdc_cde.edges <<EOF
SELECT start_node, end_node, edge_id FROM bdc_cde_topo.edge
ORDER BY start_node, end_node;
EOF

-- Calculer les sous-graphes avec NetworkX (voir script bdc_subgraphs.py)
-- et importer le résultat dans la BDD

-- Subgraph 1 : sans prise en compte des obstacles du ROE

CREATE TABLE ref.bdc_cde_015_sub1 (
    edge_id int primary key,
    sub1 int
);

\COPY ref.bdc_cde_015_sub1 FROM '/mnt/data/TEMP/015_bdc_cde_subgraph1.csv' WITH DELIMITER ' ';

CREATE TABLE ref.bdc_cde_015_subgraph1 AS
WITH subgraph AS (
    SELECT a.sub1 as graph, st_union(b.geom) as geom
    FROM ref.bdc_cde_015_sub1 a INNER JOIN bdc_cde_topo.edge b ON a.edge_id = b.edge_id
    GROUP BY a.sub1
)
SELECT row_number() over() as gid, s.*
FROM subgraph s;

ALTER TABLE ref.bdc_cde_015_subgraph1
ADD COLUMN n_mailles int;

WITH cnt AS (
    SELECT a.gid, count(b.gid)
    FROM ref.bdc_cde_015_subgraph1 a LEFT JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE ref.bdc_cde_015_subgraph1
SET n_mailles = coalesce(cnt.count, 0)
FROM cnt
WHERE bdc_cde_015_subgraph1.gid = cnt.gid;

-- Subgraph 2 : avec prise en compte des obstacles du ROE

CREATE TABLE ref.bdc_cde_015_sub2 (
    edge_id int primary key,
    sub1 int,
    sub2 int
);

\COPY ref.bdc_cde_015_sub2 FROM '/mnt/data/TEMP/015_bdc_cde_subgraph2.csv' WITH DELIMITER ' ';

CREATE TABLE ref.bdc_cde_015_subgraph2 AS
WITH subgraph AS (
    SELECT a.sub2 as graph, st_union(b.geom) as geom
    FROM ref.bdc_cde_015_sub2 a INNER JOIN bdc_cde_topo.edge b ON a.edge_id = b.edge_id
    GROUP BY a.sub2
)
SELECT row_number() over() as gid, s.*
FROM subgraph s;

ALTER TABLE ref.bdc_cde_015_subgraph2
ADD COLUMN n_mailles int;

WITH cnt AS (
    SELECT a.gid, count(b.gid)
    FROM ref.bdc_cde_015_subgraph2 a LEFT JOIN ind.grid_500m b ON st_intersects(a.geom, b.geom)
    GROUP BY a.gid
)
UPDATE ref.bdc_cde_015_subgraph2
SET n_mailles = coalesce(cnt.count, 0)
FROM cnt
WHERE bdc_cde_015_subgraph2.gid = cnt.gid;


-- Calcul final des indicateurs de connectivité cours d'eau

CREATE TABLE ind.ind_connectivite AS
WITH
conn_cde AS (
    SELECT a.gid, coalesce(max(d.n_mailles), 0) as value
    FROM ind.grid_500m a
         LEFT JOIN bdc_cde_topo.edge b ON st_intersects(a.geom, b.geom)
         INNER JOIN ref.bdc_cde_015_sub1 c ON b.edge_id = c.edge_id
         INNER JOIN ref.bdc_cde_015_subgraph1 d ON c.sub1 = d.graph
    WHERE a.dept = 'CANTAL'
    GROUP BY a.gid
),
conn_roe AS (
    SELECT a.gid, coalesce(max(d.n_mailles), 0) as value
    FROM ind.grid_500m a
         LEFT JOIN bdc_cde_topo.edge b ON st_intersects(a.geom, b.geom)
         INNER JOIN ref.bdc_cde_015_sub2 c ON b.edge_id = c.edge_id
         INNER JOIN ref.bdc_cde_015_subgraph2 d ON c.sub2 = d.graph
    WHERE a.dept = 'CANTAL'
    GROUP BY a.gid
)
SELECT g.gid,
       coalesce(a.value, 0) as n_conn_cde,
       coalesce(b.value, 0) as n_conn_roe
FROM ind.grid_500m g
     LEFT JOIN conn_cde a ON g.gid = a.gid
     LEFT JOIN conn_roe b ON g.gid = b.gid
WHERE g.dept = 'CANTAL';

ALTER TABLE ind.ind_connectivite
ADD PRIMARY KEY (gid);
