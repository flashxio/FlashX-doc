---
title: The Quick Start Guide of FlashX
keywords: Quick Start
last_updated: Nov 3, 2016
tags: [getting_started]
summary: "The Quick Start Guide for FlashX"
sidebar: mydoc_sidebar
permalink: FlashX-Quick-Start-Guide.html
folder: mydoc
---

## Install FlashR

FlashR is an R package. The installation steps have been tested in Ubuntu 14.04
and Ubuntu 16.04.

### Step 0: Library dependency
FlashR requires the following libraries: `libboost-dev, BLAS, libaio, libnuma, libhwloc`.
Users need to install these libraries before compiling the code of FlashX.
Among them, `libaio`, `libnuma` and `libhwloc` are optional. However, `libaio`
is required to take advantage of SSDs to scale computation to large datasets.
`libnuma` is required for machines with more than two processor sockets. `libhwloc`
is required to tune FlashR automatically to achieve the best speed for a given
hardware.

In Ubuntu, we install all tools and libraries for compiling FlashX as follows:

```shell
sudo apt-get update
sudo apt-get install -y g++ libboost-dev libatlas-base-dev
sudo apt-get install -y r-base-core
# This is optional
sudo apt-get install -y libnuma-dev libaio-dev libhwloc-dev
```

We rely on `devtools` to install the FlashR package in R. Users can install
`devtools` as follows:

```shell
sudo apt-get install -y libcurl4-openssl-dev libssl-dev
```

and

```R
> install.packages("devtools")
```

**NOTE**: the current `devtools` package has a bug in the low-version R framework.
Ubuntu 14.04 users should follow the instructions
[here](https://www.digitalocean.com/community/tutorials/how-to-set-up-r-on-ubuntu-14-04)
to upgrade the R framework before installing `devtools`.

### Step 1: install FlashR
Currently, FlashR is uploaded to a [Github](https://github.com/flashxio/FlashR) repo.
We can install FlashR in R with [devtools](https://cran.r-project.org/web/packages/devtools/index.html)
as follows.

```R
> library(devtools)
> install_github("flashxio/FlashR")
```

## Run FlashR.

FlashR is designed to optimize for different hardware. If FlashR is installed
with `libhwloc`, it adapts itself to different hardware automatically, from
a regular laptop (with a single processor) to a high-end server (with multiple
processors). For a machine with
SSDs, FlashR can utilize the SSDs to scale computation to very large datasets
if `libaio` is installed.

### Run FlashR in memory
If we run FlashR in memory and FlashR is installed with `libhwloc`, we do not
need to configure FlashR at all and all computation in FlashR is parallelized
automatically.

However, if FlashR is not installed with `libhwloc`, we can still maximize
the performance of FlashR by explicitly telling FlashR the number of processors
and the number of CPU cores in a machine. We configure FlashR with
`fm.set.conf` as follows, by passing a configuration file.
[Here](https://github.com/flashxio/FlashX/blob/dev-zd/matrix/conf/run_test.txt)
shows an example of the configuration file. To set the number of processors and
the number of threads, the important parameters here are `num_nodes` and `num_threads`.
For example, a machine with 4 processors and each with 12 CPU cores, we should
set `num_nodes=4` and `num_threads=48`.

```R
> fm.set.conf("path/to/conf/file")
```

### Run FlashR with SSDs.
To run FlashR with SSDs, we need to specify the data directories for FlashR
with `root_conf` in the configuration file as above (see an
[example config file](https://github.com/flashxio/FlashX/blob/dev-zd/matrix/conf/run_test.txt)).
`root_conf` accepts the path to
a text file or to a directory. If a machine has only one SSD or multiple SSDs
connected with a RAID controller, we can create a directory on the SSD(s),
and give the path to `root_conf`. For example, if the SSDs are mounted on
`/mnt/ssd` and we want to store FlashR data in `/mnt/ssd/FlashR_data`, we set
`root_conf=/mnt/ssd/FlashR_data`.

Please check [here]() for more advanced configuration
of a large SSD array on a large parallel machine.

**NOTE: to run FlashR with SSDs, it is mandatory to install FlashR with `libaio`.**

### Run an example in FlashR
FlashR implements the existing R matrix functions. As such, we can run existing
R code with little modification. Here we show an example of creating a mixture
of multivariant Gaussian and running
[k-means](https://github.com/flashxio/FlashX/blob/release/Rpkg/R/KMeans.R) on it.

First, we create `mvrnorm`, adapted from mvrnorm in the 
[MASS](https://cran.r-project.org/web/packages/MASS/index.html) package
to create multivariant normal distribution. As shown
[here](https://github.com/flashxio/FlashR-learn/commit/7143368ecfd8426cdb2197ffa1b2226fd435a024?diff=split),
we only need to modify two small places to run the function in FlashR.
We use this function to create the function `mix.mvrnorm` that constructs
a dataset under a mixture of Gaussian distributions. `mix.mvrnorm` creates `m`
normal distributions with different means and diagnoal covariance matrices and
combine them to construct a dataset.

We run k-means on the dataset to cluster data points into 10 clusters. `fm.kmeans`
outputs a vector, each of whose elements indicates the cluster id of a data point.
We run `fm.table` to count the number of data points in each cluster.

```R
mvrnorm <-
    function(n = 1, mu, Sigma, tol=1e-6, empirical = FALSE, EISPACK = FALSE)
{
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

mix.mvrnorm <- function(n, p, m)
{
    mats <- list()
    for (i in 1:m)
        mats <- c(mats, mvrnorm(n, runif(p), diag(runif(p))))
    fm.rbind.list(mats)
}

> mat <- mix.mvrnorm(1000000, 10, 10)
> res <- fm.kmeans(mat, 10, max.iters=100)
> cnt <- fm.table(res)
> as.vector(cnt$val)
 [1] 0 1 2 3 4 5 6 7 8 9
> as.vector(cnt$Freq)
 [1]  914957 1000803  982197 1058306  907314  957551 1060443 1101763 1065113
[10]  951553
```
