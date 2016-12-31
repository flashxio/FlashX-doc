---
title: The User Guide of FlashGraphR
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "The User Guide of FlashGraphR"
sidebar: mydoc_sidebar
permalink: FlashGraphR-user-guide.html
folder: mydoc
---

## Load a graph to FlashGraphR

Before running any graph algorithms on a graph, users need to first load the graph to FlashGraphR. There are multiple ways of loading a graph to FlashGraphR.

* Load a graph from a file that contains an edge list in the text format in Linux filesystem:
`g <- fg.load.graph("edge_list_file")`. FlashGraphR reads the graph in the edge list file and converts it into the FlashGraph format. The graph is kept in memory. The function returns a FlashGraphR object.
* Load a graph from a file that contains a graph in the FlashGraph format:
`g <- fg.load.graph("adj_list_file", index="index_file")`. A graph in the FlashGraph format has two parts: the graph file and the index file. When users specify an index file, FlashGraphR assumes that the input graph file is in the FlashGraph format. FlashGraphR reads the graph and its index and keeps them in memory. The function returns a FlashGraphR object.
* Load a graph from iGraph.
`g <- fg.load.igraph(ig)`. FlashGraphR converts the iGraph object into the FlashGraph format and keeps it in memory. The function returns a FlashGraphR object.
* Load a graph in the FlashGraph format to SAFS. Users need to use a SAFS tool [SAFS-util](https://github.com/icoming/FlashGraph/wiki/SAFS-user-manual#utility-tool-in-safs) to load a graph in the FlashGraph format to SAFS. Later, FlashGraphR can perform graph algorithms on the graph without loading it to memory. Right now, this is the only way of realizing the full power of FlashGraph to perform graph analysis. After loading a graph to SAFS, users need to invoke `fg.get.graph` to get a FlashGraphR object to access a graph on SAFS.

## The graph algorithms

Once a graph is loaded to FlashGraphR, users can perform graph algorithms on the graph. The graph applications supported by FlashGraph are listed below:

* weakly connected components: `fg.clusters(g, mode="weak")`
* strongly connected components: `fg.clusters(g, mode="strong")`
* graph transitivity: `fg.transitivity(g)`
* PageRank: `fg.page.rank(g)`
* triangle counting: `fg.directed.triangles(g)` and `fg.undirected.triangles(g)`
* scan statistics: `fg.topK.scan(g)` and `fg.local.scan(g)`
* coreness: `fg.coreness(g)`
* diameter estimation: `fg.diameter(g)`
* spectral clustering: `fg.spectral.clusters(g, num.clusters, which="adj")`. It supports performing spectral clustering on adjacency matrix, Laplacian matrix and normalized Laplacian matrix.

## Other functions

* `fg.list.graphs`: list all graphs loaded to FlashGraphR.
* `fg.exist.graph`: test if a graph has been loaded to FlashGraphR.
* `fg.vcount`: get the number of vertices in a graph.
* `fg.ecount`: get the number of edges in a graph.
* `fg.in.mem`: whether a graph is stored in memory or on disks.
* `fg.is.directed`: whether a graph is directed.
* `fg.degree`: get the degrees of all vertices.
* `fg.fetch.subgraph`: extract an induced subgraph.

## Examples of using FlashGraphR

Users can use R to further process the results returned from FlashGraph. Here are some examples how users process the results of the strongly connected components.

```R
# Get the strongly connected components.
# It returns an array whose elements are the component Ids of the vertices.
cc <- fg.cluster(fg, "strong")
# Get the size of each component
counts <- as.data.frame(table(cc[cc >= 0]))
# Get the largest component ID
lcc.id <- as.integer(levels(counts$Var1)[which.max(counts$Freq)])
# Get all vertices in the largest component
lcc.v <- which(cc == lcc.id)
# Get the induced subgraph with all vertices in the largest components
# Right now, this function is implemented with all data in memory, so run this function with caution.
sub.fg <- fg.fetch.subgraph(fg, vertices=lcc.v - 1, compress=FALSE)
```

Some of the graph algorithms in FlashGraphR are implemented in R by using other graph algorithms in FlashGraphR. Below show two examples of how to use existing graph algorithms in FlashGraphR to implement other graph algorithms.

One example is to compute graph transitivity. The code below computes both global and local graph transitivity for both directed and undirected graphs.

```R
    deg <- fg.degree(graph)
    if (type == "local") {
        if (graph$directed) {
            (fg.local.scan(graph) - deg) / (deg * (deg - 1))
        }
        else {
            2 * fg.undirected.triangles(graph) / (deg * (deg - 1))
        }
    }
    else {
        if (graph$directed) {
            sum(fg.local.scan(graph) - deg) / sum(deg * (deg - 1))
        }
        else {
            2 * sum(fg.undirected.triangles(graph)) / sum(deg * (deg - 1))
        }
    }
```
