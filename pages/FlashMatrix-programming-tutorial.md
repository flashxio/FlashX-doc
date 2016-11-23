---
title: The programming tutorials of FlashMatrix
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "The programming tutorials of FlashMatrix"
sidebar: mydoc_sidebar
permalink: FlashMatrix-programming-tutorial.html
folder: mydoc
---

# Examples of using FlashR

## Spectral analysis on a median-size graph
Here shows the steps of performing spectral analysis on an undirected graph with 4,036,538 vertices and 34,681,189 edges. The graph is downloaded at [SNAP](http://snap.stanford.edu/data/com-LiveJournal.html). Interested users can try this example at Amazon EC2 instance (see the instructions [here](https://github.com/icoming/FlashX/wiki/Run-FlashX-in-the-Amazon-cloud) to set up a FlashX instance) or on a local machine (see the instructions [here](https://github.com/icoming/FlashX/wiki/FlashX-Quick-Start-Guide) to install FlashX locally).

Download the graph.

```
wget http://snap.stanford.edu/data/bigdata/communities/com-lj.ungraph.txt.gz
```

Load FlashR in R.

```R
> library(FlashR)
```

FlashR loads a graph in the text edge list format and constructs a FlashGraph graph automatically. FlashR is able to construct from a zipped file. The constructed graph is an undirected graph with 4,036,538 vertices and 34,681,189 edges.

```R
> fg <- fg.load.graph("./com-lj.ungraph.txt.gz", directed=FALSE)
> fg
FlashGraph ./com-lj.ungraph.txt.gz (U): 4036538 34681189
```

We compute connected components of this graph. The result shows that all vertices with edges are connected with each other, but there are 38,576 isolated vertices.

```R
> cc <- fg.clusters(fg, mode="weak")
> table(cc)
cc
     -1       0 
  38576 3997962 
```

We extract the largest connected component from the graph and construct a new graph with the largest connected component. The new graph has 3,997,962 vertices and 34,681,189 edges.

```R
> tcc <- table(cc)
> lccV <- which(cc == as.integer(names(which(tcc == max(tcc)))))

> lcc <- fg.fetch.subgraph(fg, vertices=lccV - 1, compress=TRUE)
> lcc
FlashGraph ./com-lj.ungraph.txt.gz-sub (U): 3997962 34681189
```

We compute eigenvalues of the largest connected component.

```R
> m <- fm.get.sparse.matrix(lcc)
> multiply <- function(x, extra) m %*% x
> res <- fm.eigen(multiply, options=list(n=dim(m)[1], nev=10))
> res$vals
```

Run KMeans on the 10 eigenvectors.

```R
> kmeans.res <- fg.kmeans(as.matrix(res$vecs), k=10, max.iters=100)
```

Here summaries all the computation

```R
library(FlashR)
fg <- fg.load.graph("./com-lj.ungraph.txt.gz", directed=FALSE)
cc <- fg.clusters(fg, mode="weak")
tcc <- table(cc)
lccV <- which(cc == as.integer(names(which(tcc == max(tcc)))))
lcc <- fg.fetch.subgraph(fg, vertices=lccV - 1, compress=TRUE)
m <- fm.get.sparse.matrix(lcc)
multiply <- function(x, extra) m %*% x
res <- fm.eigen(multiply, options=list(n=dim(m)[1], nev=10))
kmeans.res <- fg.kmeans(as.matrix(res$vecs), k=10, max.iters=100)
```

## Spectral analysis on a larger graph
To compute eigenvalues of a larger graph, users may need to store the graph on SAFS. Here shows the steps of computing eigenvalues of a larger graph, which has 65,608,366 vertices and 1,806,067,135 edges. The text edge list format of the graph can be downloaded at [SNAP](http://snap.stanford.edu/data/com-Friendster.html).

To perform computation on graphs stored on SAFS, users need to construct a graph in FlashGraph format and load it to SAFS in advance. We assume users have followed the steps in shown in [FlashX Quick Start Guide](https://github.com/icoming/FlashX/wiki/FlashX-Quick-Start-Guide) to configure SAFS.

Go to the top directory of FlashX and download the graph.

```
wget http://snap.stanford.edu/data/bigdata/communities/com-friendster.ungraph.txt.gz
```

Use the tool `el2fg` to convert the edge list file in text format to the FlashGraph format. The command below creates two files `friendster.adj` and `friendster.index` and stores them to SAFS directly.

```
build/matrix/utils/el2fg -e run_test.txt com-friendster.ungraph.txt.gz friendster
```

Initialize FlashR.

```R
> library(FlashR)
> fg.set.conf("run_test.txt")
```

List all of the graphs stored on SAFS. This function lists the names of all the graphs on SAFS. To get a graph listed by this function, the graph must have two files named with `graph_name.adj` and `graph_name.index` on SAFS.

```R
> fg.list.graphs()
             name in.mem
1      friendster  FALSE
2      page-graph  FALSE
3   rmat-100M-160  FALSE
4 rmat-100M-160-u  FALSE
5    rmat-100M-40  FALSE
6  rmat-100M-40-u  FALSE
7     twitter-lcc  FALSE
8            wiki  FALSE
```

Get a reference to the friendster graph and then reference it as a sparse matrix. Note: the functions don't load a graph to memory, nor converting it to a sparse matrix physically. We support sparse matrix multiplication on a graph in the FlashGraph format.

```R
> fg <- fg.get.graph("friendster")      
> m <- fm.get.sparse.matrix(fg)
```

Compute 10 eigenvalues of the graph with FlashEigen.

```R
> multiply <- function(x, extra) m %*% x
> res <- fm.eigen(multiply, options=list(n=dim(m)[1], nev=10))
> res$vals
 [1] 693304.9 407554.7 312981.7 272623.5 257470.4 220616.7 204678.5 184447.2
 [9] 178047.9 177168.6
```

Run KMeans on the 10 eigenvectors.

```R
> kmeans.res <- fg.kmeans(as.matrix(res$vecs), k=10)
```

### PageRank

[PageRank](https://en.wikipedia.org/wiki/PageRank) is the classical algorithm to rank Web pages originally used by Google search engine. PageRank is an iterative algorithm. In each iteration, the PageRank value of a vertex is updated as follow:

![PageRank](https://upload.wikimedia.org/math/8/0/1/80125f33d12ceb608fdb9daec09d9c10.png)

As such, the PageRank algorithm is implemented as follows:

```R
pr1 <- fm.rep.int(1/N, N)
converge <- 0
while (converge < N) {
 pr2 <- (1-d)/N+d*(A %*% (pr1/out.deg))
 diff <- abs(pr1-pr2)
 converge <- sum(diff < epsilon)
 pr1 <- pr2
}
```

### Non-negative Matrix Factorization
[Non-negative Matrix Factorization](https://en.wikipedia.org/wiki/Non-negative_matrix_factorization) (NMF) factorizes a matrix to two non-negative matrices. The following code implements the algorithm described in the Lee's [paper](http://papers.nips.cc/paper/1861-algorithms-for-non-negative-matrix-factorization.pdf).
The update rules described in Lee's paper are implemented as follow

```R
den <- (t(W) %*% W) %*% H
H <- fm.pmax2(H * t(tA %*% W), eps) / (den + eps)
den <- W %*% (H %*% t(H))
W <- fm.pmax2(W * (A %*% t(H)), eps) / (den + eps)
```

One of the convergence condition is ||A - WH||^2. It is computationally expensive to compute the Frobenius norm of (A-WH) directly. Suppose A is a n×m matrix, W is a n×k matrix and H is a k×m matrix. The computation complexity is O(n×k×m). Therefore, instead of computing the Frobenius norm, we compute trace(t(A-WH)(A-WH)) = trace(t(A)A) -2×trace((t(A)W)H)+trace((t(H)(t(W)W))H). We need to order the matrix multiplication in a certain way to reduce computation complexity. The computation complexity of (t(A)W)H is O(l*k), where l is the number of non-zero entries in A. The computation complexity of (t(H)(t(W)W))H is O(k×k×n+k×k×m).

```R
# trace of W %*% H
trace.MM <- function(W, H) {
 X <- W * t(H)
 sum(X)
}

# ||A - W %*% H||^2
Fnorm <- function(A, W, H) {
 sum(A*A) - 2 * trace.MM(t(A) %*% W, H) + trace.MM(t(H) %*% (t(W) %*% W), H)
}
```

### KMeans
KMeans is another iterative algorithm that cluster data pointers. In an iteration, it has three steps and below are the steps and the corresponding FlashR code.
Step 1: calculate distances between all data points to all cluster centers.

```R
m <- fm.inner.prod(data, t(centers), fm.bo.euclidean, fm.bo.add)
```

Step 2: find the closest cluster center for each data point.

```R
parts <- fm.as.integer(fm.agg.mat(m, 1, agg.which.min) - 1)
```

Step 3: update all cluster centers.

```R
centers <- as.matrix(fm.groupby(data, 2, parts, agg.sum))
cnts <- fm.table(parts)
centers <- diag(1/cnts$Freq) %*% centers
```
