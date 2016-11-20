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
$ sudo apt-get update
$ sudo apt-get install -y g++ libboost-dev libatlas-base-dev
$ sudo apt-get install -y r-base-core
# This is optional
$ sudo apt-get install -y libnuma-dev libaio-dev libhwloc-dev
```

We rely on `devtools` to install the FlashR package in R. Users can install
`devtools` as follows:

```shell
$ sudo apt-get install -y libcurl4-openssl-dev libssl-dev
```

and

```R
> install.packages("devtools")
```

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
with `root_conf` in the configuration file as above (see an [example config file]
(https://github.com/flashxio/FlashX/blob/dev-zd/matrix/conf/run_test.txt)).
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

First, we create `fm.rmvnorm`, adapted from
[mvtnorm](https://cran.r-project.org/web/packages/mvtnorm/index.html)
to create multivariant normal distribution and use it to create 10 distributions
with different means. Then we combine the 10 datasets and run k-means on it.

```R
fm.rmvnorm <- function (n, mean = rep(0, nrow(sigma)), sigma = diag(length(mean)),
                        method = c("eigen", "svd", "chol"), pre0.9_9994 = FALSE,
                        in.mem=TRUE, name="")
{
    if (!isSymmetric(sigma, tol = sqrt(.Machine$double.eps),
                     check.attributes = FALSE)) {
        stop("sigma must be a symmetric matrix")
    }
    if (length(mean) != nrow(sigma))
        stop("mean and sigma have non-conforming size")
    method <- match.arg(method)
    R <- if (method == "eigen") {
        ev <- eigen(sigma, symmetric = TRUE)
        if (!all(ev$values >= -sqrt(.Machine$double.eps) * abs(ev$values[1]))) {
            warning("sigma is numerically not positive definite")
        }
        t(ev$vectors %*% (t(ev$vectors) * sqrt(ev$values)))
    }
    else if (method == "svd") {
        s. <- svd(sigma)
        if (!all(s.$d >= -sqrt(.Machine$double.eps) * abs(s.$d[1]))) {
            warning("sigma is numerically not positive definite")
        }
        t(s.$v %*% (t(s.$u) * sqrt(s.$d)))
    }
    else if (method == "chol") {
        R <- chol(sigma, pivot = TRUE)
        R[, order(attr(R, "pivot"))]
    }

    retval <- fm.rnorm.matrix(nrow = n, ncol=ncol(sigma), in.mem=in.mem,
                              name=name) %*% R
    # , byrow = !pre0.9_9994
    retval <- sweep(retval, 2, mean, "+")
    colnames(retval) <- names(mean)
    retval
}

mat1 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat2 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat3 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat4 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat5 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat6 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat7 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat8 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat9 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)
mat10 <- fm.rmvnorm(1000000, runif(10), in.mem = TRUE)

mat <- fm.rbind(mat1, mat2, mat3, mat4, mat5, mat6, mat7, mat8, mat9, mat10)
res <- fm.KMeans(mat, 10)
```
