import networkx as nx
import numpy as np
import sys
from networkx.exception import NetworkXError

if len(sys.argv) < 3:
    print "Usage: %s edge_file.edges roe_node_file.nodes" % sys.argv[0]
    sys.exit(0)

edge_file = sys.argv[1]
roe_node_file = sys.argv[2]
outfile = edge_file.replace('.edges', '.csv')

with open(edge_file) as f:
    graph = nx.parse_edgelist(f, nodetype=int, data=[('id', int)])

roe_nodes = list()
with open(roe_node_file) as roe:
    for line in roe:
        # roe_nodes.append(int(line))
        try:
            graph.remove_node(int(line))
        except NetworkXError:
            pass

# len(list(nx.connected_component_subgraphs(graph)))

# for i, subgraph in enumerate(nx.connected_component_subgraphs(graph, copy=False)):
#     for start_node, end_node, edge_data in subgraph.edges(data=True):
#         edge_data['sub1'] = i

# with open('015_bdc_cde_subgraph1.csv', 'w') as f:
#     for start_node, end_node, edge_data in graph.edges(data=True):
#         print >> f, edge_data['id'], edge_data['sub1']


# for node in roe_nodes:
#     graph.remove_node(node)

# len(list(nx.connected_component_subgraphs(graph)))

for i, subgraph in enumerate(nx.connected_component_subgraphs(graph, copy=False)):
    for start_node, end_node, edge_data in subgraph.edges(data=True):
        edge_data['subg'] = i

print "Writing subgraphs to %s" % outfile

with open(outfile, 'w') as f:
    for start_node, end_node, edge_data in graph.edges(data=True):
        print >> f, edge_data['id'], edge_data['subg']

print "Done."
