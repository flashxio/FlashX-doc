---
title: The programming tutorials of FlashR
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "The programming tutorials of FlashR"
sidebar: mydoc_sidebar
permalink: FlashR-tutorials.html
folder: mydoc
---

FlashR can perform computation on dense matrices, sparse matrices and graphs.
In the tutorials, we use examples to illustrate the operations on these data.
We will also illustrate the R base functions overridden by FlashR and
the [GenOps](FlashR-user-guide.html#generalized-operations-genops). Because most
computations of machine learning algorithms can be expressed with the R base
functions, many machine learning algorithms written in R can be
executed in FlashR without much modification.

## Use base R functins to generate multi-variant normal distribution
In this example, we generate random data under multi-variant normal distribution.
The code is adapted from mvrnorm in the
[MASS](https://cran.r-project.org/web/packages/MASS/index.html) package.
As shown
[here](https://github.com/flashxio/FlashR-learn/commit/7143368ecfd8426cdb2197ffa1b2226fd435a024?diff=split),
we only need to modify two small places to run the function in FlashR.

```R
mvrnorm <- function(n = 1, mu, Sigma, tol=1e-6, empirical = FALSE, EISPACK = FALSE) {
	p <- length(mu)
	if(!all(dim(Sigma) == c(p,p))) stop("incompatible arguments")
	if(EISPACK) stop("'EISPACK' is no longer supported by R", domain = NA)
	eS <- eigen(Sigma, symmetric = TRUE)
	ev <- eS$values
	if(!all(ev >= -tol*abs(ev[1L]))) stop("'Sigma' is not positive definite")
	X <- fm.rnorm.matrix(n, p)
	if(empirical) {
		X <- scale(X, TRUE, FALSE) # remove means
		X <- X %*% fm.svd(X, nu = 0)$v # rotate to PCs
		X <- scale(X, FALSE, TRUE) # rescale PCs to unit variance
	}
	X <- drop(mu) + eS$vectors %*% diag(sqrt(pmax(ev, 0)), p) %*% t(X)
	nm <- names(mu)
	if(is.null(nm) && !is.null(dn <- dimnames(Sigma))) nm <- dn[[1L]]
	dimnames(X) <- list(nm, NULL)
	if(n == 1) drop(X) else t(X)
}
```

## Use GenOps to compute k-means
K-means is a simple but popular clustering algorithm. We use this algorithm
as an example to illustrate GenOps for efficient computation.

K-means is an iterative algorithm and each iteration has three steps.
Below is the simplified code to illustrate the three steps. The complete code
of k-means is [here](https://github.com/flashxio/FlashX/blob/dev/Rpkg/R/KMeans.R).

```R
# Step 1: calculate distances between all data points to all cluster centers.
dist <- fm.inner.prod(data, t(centers), fm.bo.euclidean, fm.bo.add)

# Step 2: find the closest cluster center for each data point.
parts <- fm.agg.mat(dist, 1, agg.which.min)

# Step 3: update all cluster centers.
centers <- as.matrix(fm.groupby(data, 2, parts, agg.sum))
cnts <- as.vector(fm.table(parts))
centers <- diag(1/cnts) %*% centers
```

The complete implementation of k-means is shown below. This is a simplified
version of the [k-means](https://github.com/flashxio/FlashX/blob/dev/Rpkg/R/KMeans.R)
implementation in FlashR. In the end, we run the k-means implementation
as shown above on a matrix loaded from a CSV file.

```R
kmeans <- function(data, k, max.iters)
{
	agg.sum <- fm.create.agg.op(fm.bo.add, fm.bo.add, "sum")
	agg.which.min <- fm.create.agg.op(fm.bo.which.min, NULL, "which.min")

	# randomly select k data points as centers.
	centers <- data[runif(k, min=1, max=nrow(data)),]
	iter <- 0
	while (iter < max.iters) {
		# Step 1: calculate distances between all data points to all cluster centers.
		dist <- fm.inner.prod(data, t(centers), fm.bo.euclidean, fm.bo.add)

		# Step 2: find the closest cluster center for each data point.
		parts <- fm.agg.mat(dist, 1, agg.which.min) - 1
		# Cache this matrix in memory.
		fm.set.cached(parts, TRUE, TRUE)

		# Step 3: update all cluster centers.
		centers <- as.matrix(fm.groupby(data, 2, fm.as.factor(parts, k),
					agg.sum))
		cnts <- as.vector(fm.table(parts)@Freq)
		centers <- diag(1/cnts) %*% centers

		iter++
	}
	parts
}

mat <- fm.load.dense.matrix("./test_mat.csv", ele.type="D", delim=",", in.mem=TRUE)
kmeans(mat, 5, 10)
```

## Use FlashR for matrix factorization (Non-negative Matrix Factorization)
[Non-negative Matrix Factorization](https://en.wikipedia.org/wiki/Non-negative_matrix_factorization)
(NMF) factorizes a matrix to two non-negative matrices. There are many algorithms
to factorize a matrix into two non-negative matrices. The following code
implements the algorithm described in the Lee's [paper](http://papers.nips.cc/paper/1861-algorithms-for-non-negative-matrix-factorization.pdf).
The update rules described in Lee's paper are implemented as follow

```R
den <- (t(W) %*% W) %*% H
H <- pmax(H * t(tA %*% W), eps) / (den + eps)
den <- W %*% (H %*% t(H))
W <- pmax(W * (A %*% t(H)), eps) / (den + eps)
```

One of the convergence condition is `||A - WH||^2`. It is computationally
expensive to compute the Frobenius norm of `(A-WH)` directly. Suppose `A`
is a n x m matrix, `W` is a n x k matrix and `H` is a k x m matrix.
The computation complexity is O(n * k * m). Therefore, instead of computing
the Frobenius norm, we compute
`trace(t(A-WH)(A-WH)) = trace(t(A)A) -2 * trace((t(A)W)H)+trace((t(H)(t(W)W))H)`.
We need to order the matrix multiplication in a certain way to reduce computation
complexity. The computation complexity of `(t(A)W)H` is `O(l*k)`, where `l` is
the number of non-zero entries in `A`. The computation complexity of `(t(H)(t(W)W))H`
is O(k * k * n + k * k * m).

```R
# trace of W %*% H
trace.MM <- function(W, H) sum(W * t(H))

# ||A - W %*% H||^2
Fnorm <- function(A, W, H) {
 sum(A*A) - 2 * trace.MM(t(A) %*% W, H) + trace.MM(t(H) %*% (t(W) %*% W), H)
}
```

## Use FlashR for graph algorithms (PageRank)
We can also use FlashR to compute some classical graph algorithms, such as
[PageRank](https://en.wikipedia.org/wiki/PageRank). This algorithm is used by
Google search engine to rank Web pages. PageRank is an iterative algorithm.
In each iteration, the PageRank value of a vertex is updated as follow:

![PageRank](https://upload.wikimedia.org/math/8/0/1/80125f33d12ceb608fdb9daec09d9c10.png)

As such, the PageRank algorithm is implemented as follows. In this implementation,
we store a graph in a sparse matrix `graph` and the key operation is sparse matrix
multiplication. The complete code is
[here](https://github.com/flashxio/FlashX/blob/dev/FlashR-learn/R/graph-algs.R).

```R
pagerank <- function(graph, d=0.15, epsilon=1e-2) {
	N <- nrow(graph)
	pr1 <- fm.rep.int(1/N, N)
	out.deg <- graph %*% fm.rep.int(1, N)
	converge <- 0
	graph <- t(graph)
	while (converge < N) {
		pr2 <- (1-d)/N+d*(graph %*% (pr1/out.deg))
		diff <- abs(pr1-pr2)
		converge <- sum(diff < epsilon)
		pr1 <- pr2
	}
	pr1
}

graph <- fm.load.sparse.matrix("../wiki-Vote.txt", is.sym=FALSE, delim="\t")
pagerank(graph)
```

## Use FlashR with FlashGraphR for spectral analysis on graphs
Another example of using FlashR for graph analysis is spectral analysis.
This example illustrates how to use FlashR and FlashGraphR together.
Here shows the steps of performing spectral analysis on an undirected graph
with 4,036,538 vertices and 34,681,189 edges. The graph is downloaded at
[SNAP](http://snap.stanford.edu/data/com-LiveJournal.html).

Download the graph.

```
wget http://snap.stanford.edu/data/bigdata/communities/com-lj.ungraph.txt.gz
```

First, we use FlashGraphR to load a graph in the text edge list format and
constructs a graph in the FlashGraph format. FlashGraphR is able to construct
from a zipped file (if the feature is enabled). The constructed graph is
an undirected graph with 4,036,538 vertices and 34,681,189 edges.

```R
> fg <- fg.load.graph("./com-lj.ungraph.txt", directed=FALSE)
> fg
FlashGraph ./com-lj.ungraph.txt.gz (U): 4036538 34681189
```

We compute connected components of this graph. The result shows that all
vertices with edges are connected with each other, but there are 38,576
isolated vertices.

```R
> cc <- fg.clusters(fg, mode="weak")
```

We extract the largest connected component from the graph and construct
a new graph with the largest connected component. The new graph has 3,997,962
vertices and 34,681,189 edges.

```R
> tcc <- fm.table(cc)
> max.idx <- which(as.vector(tcc@Freq == max(tcc@Freq)))
> lccV <- which(as.vector(cc == tcc@val[max.idx]))

> lcc <- fg.fetch.subgraph(fg, vertices=lccV - 1, compress=TRUE)
> lcc
FlashGraph ./com-lj.ungraph.txt.gz-sub (U): 3997962 34681189
```

We can save the largest connected component in the FlashGraph format to local files for future use.

```R
> fg.export.graph(lcc, "lj-lcc.adj", "lj-lcc.index")
```

In the future, if we want to load the largest connected component to FlashGraphR, we can run the instruction below.

```R
> lcc <- fg.load.graph("./lj-lcc.adj", "./lj-lcc.index")
```

We compute eigenvalues of the largest connected component.

```R
> m <- fg.get.sparse.matrix(lcc)
> multiply <- function(x, extra) m %*% x
> res <- fm.eigen(multiply, k=10, n=nrow(m), which="LM", sym=TRUE)
> res$vals
```

Run KMeans on the 10 eigenvectors.

```R
> kmeans.res <- fm.kmeans(res$vectors, 10, max.iters=100)
```
