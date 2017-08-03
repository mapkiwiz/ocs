#!/usr/bin/python

import networkx as nx
import numpy as np
import sys

edge_file = sys.argv[1]
outfile = edge_file.replace('.edges', '.subgraphs')

with open(edge_file) as f:
    graph = nx.parse_edgelist(f, nodetype=int)

for i, subgraph in enumerate(nx.connected_component_subgraphs(graph, copy=False)):
    for start_node, end_node, edge_data in subgraph.edges(data=True):
        edge_data['subg'] = i

with open(outfile, 'w') as f:
    for start_node, end_node, edge_data in graph.edges(data=True):
        if end_node > start_node:
            print >> f, start_node, edge_data['subg']
        else:
            print >> f, end_node, edge_data['subg']

print "Ok - subgraphs written to %s" % outfile