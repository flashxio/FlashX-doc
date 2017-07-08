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

## Load and initialize FlashGraphR

Users can call `fg.set.conf` to initialize FlashGraphR. Users can specify the number of threads to use and enable FlashGraphR to use SSDs to process large graphs. [Here](https://github.com/flashxio/FlashX/blob/release/flash-graph/conf/run_test.txt) shows an example of a configuration file. [This page](https://flashxio.github.io/FlashX-doc/FlashX-config.html) explains important parameters in the configuration file.

```R
> library(FlashGraphR)
> fg.set.conf("/path/to/conf/file")
```

## Load a graph to FlashGraphR

Before running any graph algorithms on a graph, users need to first load the graph to FlashGraphR. There are multiple ways of loading a graph to FlashGraphR.

* Load a graph from a text file that contains an edge list in Linux filesystem:
`g <- fg.load.graph("/path/to/edge/list/file")`. FlashGraphR reads the graph in the edge list file and converts it into the FlashGraph format. The graph is kept in memory. The function returns a FlashGraphR object. To utilize SSDs, a user should pass `in.mem=FALSE` to this function. In this case, the graph is constructed and stored on SSDs.
* Load a graph from a file that contains a graph in the FlashGraph format:
`g <- fg.load.graph("/path/to/adj/list/file", index="/path/to/index/file")`. A graph in the FlashGraph format has two parts: the graph file and the index file. When users specify an index file, FlashGraphR assumes that the input graph file is in the FlashGraph format. FlashGraphR reads the graph and its index and keeps them in memory. The function returns a FlashGraphR object.

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
* spectral embedding: `fg.spectral.embedding(g, nev)`. It supports performing spectral embedding on an adjacency matrix, a Laplacian matrix and a normalized Laplacian matrix.

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

Compute spectral embedding on the largest connected component in a graph.

```R
library(FlashGraphR)
fg.set.conf("flash-graph/conf/run_test.txt")
# Load the Facebook graph as an undirected graph.
fg <- fg.load.graph("/mnt/nfs/graph-data/facebook_combined.txt", directed=FALSE)
# Get the strongly connected components.
# It returns an array whose elements are the component Ids of the vertices.
cc <- fg.clusters(fg, "weakly")
# Get the size of each component
counts <- as.data.frame(fm.table(cc[cc >= 0]))
# Get the largest component ID
lcc.id <- as.vector(counts$val)[which.max(as.vector(counts$Freq))]
# Get all vertices in the largest component
lcc.v <- which(cc == lcc.id)
# Get the induced subgraph with all vertices in the largest components
# The function outputs a graph in the FlashGraph format.
sub.fg <- fg.fetch.subgraph(fg, vertices=lcc.v, compress=FALSE)
# Compute spectral embedding on the largest connected component.
res <- fg.spectral.embedding(sub.fg, 10, which="A")
# Use kmeans to cluster the vertices.
clus.res <- kmeans(res$vectors, 10)
```
