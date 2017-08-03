CREATE TABLE aux.bdc_topo as
SELECT a.* from ref.bdc_cours_eau_2014 a,
       ind.dept_ta b
WHERE st_intersects(a.geom, b.geom);

ALTER TABLE aux.bdc_topo
ADD PRIMARY KEY (gid) ;

CREATE INDEX bdc_topo_geom_idx
ON aux.bdc_topo USING GIST (geom);

SELECT topology.AddTopoGeometryColumn('bdc_topo_2', 'aux', 'bdc_topo', 'topo_geom', 'LINESTRING') ;

UPDATE aux.bdc_topo
SET topo_geom = topology.toTopoGeom(st_force2d(geom), 'bdc_topo_2', 1, 1.0);

CREATE TABLE aux.bdc_roe_topo as
SELECT DISTINCT a.*
FROM ref.bdc_roe a,
       ind.dept_ta b
WHERE st_intersects(a.geom, b.geom);

ALTER TABLE aux.bdc_roe_topo
ADD PRIMARY KEY (gid) ;

CREATE INDEX bdc_roe_topo_geom_idx
ON aux.bdc_roe_topo USING GIST (geom);

SELECT topology.AddTopoGeometryColumn('bdc_topo_2', 'aux', 'bdc_roe_topo', 'topo_geom', 'POINT') ;

UPDATE aux.bdc_roe_topo  
SET topo_geom = topology.toTopoGeom(st_force2d(geom), 'bdc_topo_2', 2, 1.0);

-- Exporter la liste des arêtes dans un fichier CSV

psql -A -F " " -t > /tmp/aura_bdc.edges <<EOF
    SELECT start_node, end_node, edge_id
    FROM bdc_topo_2.edge
    -- WHERE EXISTS (
    --     SELECT
    --     FROM bdc_topo_2.node a
    --     INNER JOIN bdc_topo_2.relation b ON a.node_id = b.element_id
    --     WHERE (a.node_id = edge.start_node OR a.node_id = edge.end_node)
    --       AND b.layer_id = 1 -- aux.bdc_cde_topo
    -- )
    ORDER BY start_node, end_node;
EOF

-- Exporter la liste des noeuds du ROE dans un fichir CSV

psql -A -F " " -t > /tmp/aura_roe.nodes <<EOF
    SELECT DISTINCT a.node_id
    FROM bdc_topo_2.node a
    INNER JOIN bdc_topo_2.relation b ON a.node_id = b.element_id
    WHERE b.element_type = 1 -- POINT
      AND b.layer_id = 2 -- aux.bdc_roe_topo
      AND EXISTS (
        SELECT edge_id FROM bdc_topo_2.edge WHERE start_node = a.node_id or end_node = a.node_id
      ); 
EOF

-- Calculer les sous-graphes avec NetworkX (voir script bdc_subgraphs.py)
-- et importer le résultat dans la BDD

-- Subgraph 1 : sans prise en compte des obstacles du ROE

CREATE TABLE aux.bdc_cde_subg (
    edge_id int primary key,
    subg int
);

\COPY aux.bdc_cde_subg FROM '/tmp/aura_bdc.csv' WITH DELIMITER ' ';

CREATE TABLE ind_aura.conn_cde AS
WITH
subgraph AS (
    SELECT a.subg, (st_dump(st_union(b.geom))).geom
    FROM aux.bdc_cde_subg a
    INNER JOIN bdc_topo_2.edge b ON a.edge_id = b.edge_id
    GROUP BY a.subg
),
rel AS (
    SELECT a.subg, b.gid
    FROM subgraph a 
    INNER JOIN ind.grid_500m b
    ON st_intersects(a.geom, b.geom) 
),
subg_size AS (
    SELECT subg, count(gid) AS size
    FROM rel
    GROUP BY subg
)
SELECT a.gid, max(b.size)
FROM rel a
INNER JOIN subg_size b
ON a.subg = b.subg
GROUP BY a.gid;