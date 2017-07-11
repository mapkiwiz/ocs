import networkx as nx
import numpy as np

with open('015_bdc_cde.edges') as f:
    graph = nx.parse_edgelist(f, nodetype=int, data=[('id', int)])

roe_nodes = list()
with open('015_bdc_cde_roe.nodes') as roe:
    for line in roe:
        roe_nodes.append(int(line))

len(list(nx.connected_component_subgraphs(graph)))

for i, subgraph in enumerate(nx.connected_component_subgraphs(graph, copy=False)):
    for start_node, end_node, edge_data in subgraph.edges(data=True):
        edge_data['sub1'] = i

with open('015_bdc_cde_subgraph1.csv', 'w') as f:
    for start_node, end_node, edge_data in graph.edges(data=True):
        print >> f, edge_data['id'], edge_data['sub1']


for node in roe_nodes:
    graph.remove_node(node)

len(list(nx.connected_component_subgraphs(graph)))

for i, subgraph in enumerate(nx.connected_component_subgraphs(graph, copy=False)):
    for start_node, end_node, edge_data in subgraph.edges(data=True):
        edge_data['sub2'] = i

with open('015_bdc_cde_subgraph2.csv', 'w') as f:
    for start_node, end_node, edge_data in graph.edges(data=True):
        print >> f, edge_data['id'], edge_data['sub2'], edge_data['sub2']
