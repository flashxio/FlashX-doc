---
title: The User Guide of FlashMatrix
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "The User Guide of FlashMatrix"
sidebar: mydoc_sidebar
permalink: FlashMatrix-user-guide.html
folder: mydoc
---

FlashR extends the R programming framework for large-scale data analysis. It executes R code in parallel automatically and utilizes disks to scale R to large datasets. The core of FlashR is a small set of generalized matrix operations to perform computation in an array-oriented fashion. In addition, FlashR reimplements many commonly used R functions in the [base](https://stat.ethz.ch/R-manual/R-devel/library/base/html/00Index.html) and [stats](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/00Index.html) packages to provide users a familiar R programming environment to reduce the learning curve. FlashR is completely implemented as an R package.

Although FlashR tries to provide a familiar environment for R users, some operations in the R framework are not supported in FlashR. The biggest difference is that FlashR does not allow users to modify individual elements in a vector or a matrix. FlashR intentionally chooses so for the sake of performance. FlashR stores vectors and matrices on SSDs. Modifying individual elements results in read-modify-write to SSDs, which causes many small random I/O. It causes efficiency issues and these operations are harmful to SSDs. By forbidding modifying individual elements, FlashR advocates array-oriented programming to achieve superior efficiency.

## How to start

Users can follow the [instructions](https://flashxio.github.io/FlashX-doc/FlashX-Quick-Start-Guide.html) to install FlashR in Ubuntu. To load FlashR to R, run

```R
> library(FlashR)
```

## Construct FlashR vectors and matrices

FlashR provides a set of functions to generate FlashR vectors and matrices. These functions have similar interface to the R counterparts.

The following functions generate FlashR vectors:

* `fm.rep.int`: create a vector with replicated elements. e.g., `fm.rep.int(1, 10)` creates a FlashR vector with 10 elements and each element is 1.
* `fm.seq.int`: create a vector with a sequence of numbers. e.g., `fm.seq.int(1, 10, 1)` creates a FlashR vector with a sequence of numbers between [1:10].
* `fm.runif`: create a vector with uniformly random numbers. e.g., `fm.runif(10, 0, 1, in.mem=TRUE)` creates a FlashR vector with 10 uniformly random values between 0 and 1, stored in memory. `in.mem` instructs FlashR to store data in memory or on disks.
* `fm.rnorm`: create a vector under normal distribution. e.g., `fm.rnorm(10, 0, 1, in.mem=TRUE)` creates a FlashR vector with 10 random values following normal distribution with mean 0 and standard deviation 1 and stores data in memory. Like the one in `fm.runif`, `in.mem` instructs FlashR to store data in memory or on disks.

The following functions generate FlashR matrices:

* `fm.matrix`: create a matrix filled with repeated values from an R object. e.g., `fm.matrix(0, 10, 2)` creates a 10x2 FlashR matrix with 0.
* `fm.seq.matrix`: create a matrix filled with sequence numbers. e.g., `fm.seq.matrix(0, 20, 10, 2)` creates a 10x2 FlashR matrix with columns filled with 1:20.
* `fm.runif.matrix`: create a matrix filled with uniform random numbers. e.g., `fm.runif.matrix(10, 2, 0, 1, in.mem=TRUE)` creates a 10x2 FlashR matrix with 20 uniformly random values between 0 and 1, stored in memory.
* `fm.rnorm.matrix`: create a matrix filled under normal distribution. e.g., `fm.rnorm.matrix(10, 2, 0, 1, in.mem=TRUE)` creats a 10x2 FlashR matrix with 20 random values following normal distribution with mean 0 and standard deviation 1, and stores data in memory.

The following functions load data outside the FlashR environment.

* `fm.load.dense.matrix`: load a dense matrix from a text file. Each line in the text file stores a row of the dense matrix. Users need to specify a delimiter and the function assumes "," by default. Users can also specify the element type and by default the function assumes floating-point. The available element types are "D" for floating-point values, "I" for integers, "L" for logical values. Users can also specify the number of columns in the dense matrix. If not, the function will try to determine the number of columns itself. e.g., `fm.load.dense.matrix("/mnt/data/matrix.csv", in.mem=TRUE, ele.type="I", delim=",", ncol=10)` loads a dense matrix of integers with 10 columns from a CSV file.
* `fm.load.dense.matrix.bin`: load a dense matrix from a binary file. The binary file can store data in row-major or column-major order. In this function, users have to specify all information of the dense matrix, such as the number of rows, the number of columns, the element type and the data layout (row-major or column-major). e.g., `fm.load.dense.matrix.bin("/mnt/data/matrix.bin", in.mem=TRUE, nrow=1000, ncol=10, byrow=FALSE, ele.type="I")` loads a dense matrix of integers with 1000 rows and 10 columns, stored in column-major order.
* `fm.load.sparse.matrix`: load a sparse matrix in the FlashMatrix format from the Linux filesystem. The sparse matrix has to be formatted in advance. For a symmetric matrix, users only need to specify the sparse matrix file and the index file of the sparse matrix. For an asymmetric matrix, users need to specify four files: the sparse matrix file, the index file of the sparse matrix, the transpose of the sparse matrix, the index file for the transpose of the sparse matrix.

## Interact with native R

FlashR also provides functions to interact with the original R system.

* `fm.as.vector`: convert an R vector/matrix and a FlashR matrix to a FlashR vector. The current implementation only supports converting from a one-column FlashR matrix to a FlashR vector.
* `fm.as.matrix`: convert an R vector/matrix and a FlashR vector to a FlashR matrix. A vector is converted into a one-column matrix.
* `fm.as.factor`: convert a FlashR vector to a factor vector. The current implementation only supports converting an integer vector. By default, this function determines the number of levels in the factor vector automatically. Users can also provide a maximal number of levels. Right now, FlashR factor vectors are used by `fm.sgroupby` and `fm.groupby`.
* [`as.vector`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/vector.html): convert a FlashR vector/matrix to a R vector.
* [`as.matrix`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/matrix.html): convert a FlashR vector/matrix to a R matrix.
* `fm.conv.FM2R`: convert a FlashR vector or matrix to an R vector or matrix respectively.
* `fm.conv.R2FM`: convert an R vector or matrix to a FlashR vector or matrix respectively.

FlashR has the following functions to test if an object is a FlashR vector or matrix.

* `fm.is.vector`: test if an object is a FlashR vector.
* `fm.is.matrix`: test if an object is a FlashR matrix.

## "Base" R functions

FlashR implements many R functions in the base package to mimic the existing R programming environment. Although we have a goal of having these functions as similar as possible to the original R functions, we do not provide 100% compatibility with the original R version for some functions for the sake of performance. Below shows a list of R functions in the base package currently supported by FlashR. More functions will be provided in the future.

The following functions have exactly the same interface as the original R function.

* matrix info: `dim`, `nrow`, `ncol`, `length`, `typeof`
* change matrix shape: `t`
* element-wise unary: `abs`, `sqrt`, `ceiling`, `floor`, `round`, `log`, `log2`, `log10`, `exp`, `!`, `-`
* inner product: `%*%`, `crossprod`, `tcrossprod`
* aggregation: `sum`, `min`, `max`, `range`, `all`, `any`, `mean`, `rowSums`, `colSums`, `rowMeans`, `colMeans`, `sd`, `cov`, `cov.wt`
* type cast: `as.integer`, `as.numeric`
* extract element: `[]`, `head`, `tail`

Many operations have exactly the same interface as the original R functions but perform computation slightly differently in certain cases.

* binary operations: `+`, `-`, `*`, `/`, `^`, `==`, `!=`, `>`, `>=`, `<`, `<=`, `|`, `&`. When they are applied to a matrix and a vector, it requires the vector has the same length as the columns of the matrix.
* [`sweep`](http://stat.ethz.ch/R-manual/R-patched/library/base/html/sweep.html) requires the vector in `STATS` has the same length as the rows or the columns of the matrix in `x`. In addition, the function in `FUN` has to be one of the pre-defined functions in FlashR (see the section "Generalized operations").
* [`print`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/print.html): instead of printing the elements in a FlashR vector/matrix, this function prints the basic information of the FlashR object, such as the number of rows or columns.
* [`pmin`, `pmax`](https://stat.ethz.ch/R-manual/R-devel/library/base/html/Extremes.html) requires input arrays to be all FlashR vectors or FlashR matrices. Thess functions do not work on a mix of FlashR vectors/matrices and R vectors/matrices. In addtion, we create `pmin2` and `pmax2` to compute parallel maxima and minima of two input vectors/matrices.

Some of them have slightly different interface and semantics. These slightly different functions always start with "fm." to indicate that they are actually FlashR functions. In the future, we will provide implementations with exactly the same interface and semantics as the original R functions.

* `fm.table`: builds a contingency table of the counts of unique elements in the input vector. It currently only works for FlashR vectors and factor vectors. It outputs a list with two FlashR vectors: `val` and `Freq`. `val` contains the unique values in the input vector and `Freq` contains the counts of the unique values.

## Generalized operations

FlashR has two sets of programming API. It provides users a set of generalized operators, with which users can implement varieties of data mining and machine learning algorithms. On top of them, FlashR implements many R functions in the base package with the generalized operators to mimic the original R programming environment.
Generalized operators

Generalized operators (GenOp) are the core of FlashR. There are a very small number of GenOps in FlashR. Each operator accepts a user-defined operator (UDO) or the name of a UDO to perform users' tasks. Currently, there are four GenOps, but some of them have multiple forms. There are many UDOs in FlashR such as addition and subtraction (see `?fm.basic.op` for details). Below lists all GenOps currently supported by FlashR.

**Inner product**: a generalized matrix multiplication. It replaces multiplication and addition in matrix multiplication with two UDOs, respectively. As such, we can define many operations with inner product. For example, we can use inner product to compute various pair-wise distance matrics of data points such as Euclidean distance and Hamming distance.

```
fm.inner.prod(fm, mat, FUN1, FUN2)
```

One example of using `fm.inner.prod` is to compute a pair-wise distance between every data point. `fm.bo.euclidean` and `fm.bo.add` are some UDOs written in C++. `fm.bo.euclidean` computes `(x-y)*(x-y)`. `fm.bo.add` computes `x + y`.
`fm.inner.prod(data, t(data), fm.bo.euclidean, fm.bo.add)`

**Apply**: a generalized form of element-wise operations and has multiple variants.

* `fm.sapply`:  a generalized element-wise unary operation whose UDO takes an element in a vector or a matrix at a time and outputs an element.
* `fm.mapply2`: a generalized element-wise binary operation whose UDO takes an element from each vector or matrix and outputs an element.
* `fm.mapply.row` and `fm.mapply.col` are two variants of `fm.mapply2`. They are similar to `sweep()` in R and the broadcasting mechanism in Numpy. They are equivalent to mapply2 on every row or column of the matrix (in the first argument) with the vector (in the second argument). Currently, `fm.mapply.row` and `fm.mapply.col` only accept the cases that the vector has the same length as a row or a column of the matrix.

```
fm.sapply(o, FUN)
fm.mapply2(o1, o2, FUN)
fm.mapply.row(o1, o2, FUN)
fm.mapply.col(o1, o2, FUN)
```

`fm.multiply`

lazy evaluation.

Many matrix operations in FlashR are implemented with `fm.sapply` and `fm.mapply2`.
Example 1: compute m1 + m2

`fm.mapply2.fm(m1, m2, fm.bo.add)`

Example 2: compute -m1

`fm.sapply(m1, fm.buo.neg)`

These are some examples of using `fm.sapply` and `fm.mapply2`. Both matrix addition and matrix negation have been implemented in FlashR.

Aggregation takes multiple elements and outputs a single element.

* `fm.agg`: aggregates over the entire vector or matrix.
* `fm.agg.mat`: aggregates over each individual row or column of a matrix and outputs a vector.

```
fm.agg(fm, FUN)
fm.agg.mat(fm, margin, FUN)
```

Example 1: compute sum(m)

`fm.agg(x, fm.bo.add)`

Example 2: compute rowSums(m)

`fm.agg.mat(x, 1, fm.bo.add)`

Again, both `sum()` and `rowSums()` have been implemented with aggregation in FlashR.

Groupby is similar to groupby in SQL. It groups multiple elements by their values and perform some computation on the elements. Currently, the function passed to a groupby function has to aggregate values.
`fm.sgroupby`:  groups elements by their values in a vector and invokes UDO on the elements associated with the same value. It outputs a vector.
`fm.groupby`: takes a matrix and a vector of categorical values, groups rows/columns of the matrix based on the corresponding categorical value and runs UDO on the rows/columns with the same categorical value. It outputs a matrix.

```
fm.sgroupby(o, FUN)
fm.groupby(fm, margin, factor, FUN)
```

In practice, groupby requires an aggregation operation over some of the original elements in a group and combine operation over the aggregation results. The reason is that groupby runs in parallel and each time it can only aggregate over some of the elements in a group. Essentially, the combine operation is an aggregation. Usually, it is sufficient to pass a UDO to a groupby function because a UDO can work as both aggregation and combine. In some cases, however, we need these operations to be different. As such, users can pass an aggregation operator to groupby. A user can create an aggregation operator themselves by calling fm.create.agg.op() and specify two UDOs for the aggregation and combine operation.
fm.create.agg.op(agg, combine, name)

## FlashR object information

* `fm.is.sym`
* `fm.matrix.layout`
* `fm.is.sparse`
* `fm.is.sink`
* `fm.in.mem`

## FlashR configuration

* `fm.print.features`
* `fm.set.conf`

## Lazy evaluation and matrix materialization

FlashR gains performance by lazily evaluating most of the matrix operations and merging them into a single execution. As such, most of the matrices output from a matrix operation do not contain actual computation results. By default, only the operations that output an R scalar value perform actual computation when the function is called. The computation can also be triggered when a user wants to convert FlashR vectors/matrices to R vectors/matrices. Users can also explicitly force FlashR to perform computation by invoking `fm.materialize` and `fm.materialize.list`. In addition, users can set a flag on a matrix to notify FlashR to save the materialized results.

## Some examples of using FlashR

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

## Requirements for FlashR users

There are two requirements for FlashR users to get the best performance out of FlashR:

* Array-oriented programming
* Understand space & computation complexity
