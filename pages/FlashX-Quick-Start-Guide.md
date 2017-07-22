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

## Install FlashX

This document shows the installation of FlashX with the R programming interfaces.
Currently, FlashX provides R interfaces: FlashR and FlashGraphR.
The installation steps have been tested in Ubuntu 14.04 and Ubuntu 16.04.

### Library dependency

To install FlashX, users need to install R first.
In Ubuntu, users can install FlashR as follows:

```shell
$ sudo sh -c "echo \"deb http://cran.rstudio.com/bin/linux/ubuntu xenial/\" >> /etc/apt/sources.list"
$ sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9
$ sudo apt-get update
$ sudo apt-get install -y r-base-core
```
To run FlashX faster and use disks to scale to large datasets, users
needs to install some additional libraries: `libaio, libnuma, libhwloc, libatlas`.
All of the libraries are **optional**. Users need to install these
libraries before compiling the code of FlashX.

* `libaio` is required to take advantage of SSDs to scale computation to large datasets.
* `libnuma` is required for machines with more than two processor sockets.
* `libhwloc` is required to tune FlashX automatically to achieve the best speed for a given hardware.
* `libatlas` is a faster BLAS implementation and it can accelerate matrix multilication in FlashR.

In Ubuntu, users can install the additional libraries as follows:

```shell
sudo apt-get install -y libnuma-dev libaio-dev libhwloc-dev
sudo apt-get install -y libatlas-base-dev
```

Users can use `devtools` or use a URL link to install FlashR and FlashGraphR in R.
If users choose to use `devtools`, they need to install `devtools` first:

```shell
sudo apt-get install -y libcurl4-openssl-dev libssl-dev
R -e "install.packages('devtools', repos = 'http://cran.rstudio.com/')"
```

**NOTE**: the current `devtools` package has a bug in the low-version R framework.
Ubuntu 14.04 users should follow the instructions
[here](https://www.digitalocean.com/community/tutorials/how-to-set-up-r-on-ubuntu-14-04)
to upgrade the R framework before installing `devtools`.

### Install FlashR & FlashGraphR from Github directly
FlashR is uploaded to a [Github](https://github.com/flashxio/FlashR) repo and FlashGraphR is uploaded to a [Github](https://github.com/flashxio/FlashGraphR) repo.
We can install FlashR & FlashGraphR in R with [devtools](https://cran.r-project.org/web/packages/devtools/index.html)
as follows.

```R
> library(devtools)
> install_github("flashxio/FlashR")
```

If a user don't want to install devtools or can't install devtools, he or she
can install FlashR with the following link directly. Unfortunately, the user
needs to install the dependencies manually.

```R
> install.packages("Rcpp")
> install.packages("RSpectra")
> install.packages("https://github.com/flashxio/FlashR/archive/FlashR-latest.tar.gz", repos=NULL)
```

Similarly, we can install FlashGraphR as follows:

```R
> library(devtools)
> install_github("flashxio/FlashGraphR")
```

### Install FlashR & FlashGraphR manually
Another option of installing FlashR and FlashGraphR is to download from Github and install them manually.
The benefit of such an approach is to customize the installation process. For example, this allows us to compile the code in parallel.

```shell
$ git clone https://github.com/flashxio/FlashX.git
$ cd FlashX
$ mkdir -p build; cd build; cmake ../; make -j4; cd ..
$ RUN R -e "install.packages('Rcpp', repos = 'http://cran.rstudio.com/')"
$ RUN R -e "install.packages('RSpectra', repos = 'http://cran.rstudio.com/')"
$ RUN R -e "install.packages('igraph', repos = 'http://cran.rstudio.com/')"
$ ./install_FlashR.sh
$ ./install_FlashGraphR.sh
```

### Install FlashX in a docker container

If a user chooses to install FlashR and FlashGraphR in a docker container,
the user needs to clone the FlashX repository and follows the steps below
to install it.
```
$ git clone https://github.com/flashxio/FlashX.git
$ cd FlashX
$ docker build -t flashx docker
$ docker run -d flashx
$ docker exec -it <container id> bash
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
set `num_nodes=4` and `num_threads=48`. A complete list of parameters of FlashR can be
found [here](https://flashxio.github.io/FlashX-doc/FlashX-conf.html).

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

Please check [here](https://flashxio.github.io/FlashX-doc/FlashX-conf.html) for
more advanced configuration of a large SSD array on a large parallel machine.

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
> as.vector(cnt@val)
 [1] 0 1 2 3 4 5 6 7 8 9
> as.vector(cnt@Freq)
 [1]  914957 1000803  982197 1058306  907314  957551 1060443 1101763 1065113
[10]  951553
```

## Run FlashGraphR
Users can run graph algorithms provided by FlashGraphR.

Users can load a graph in both text edge list format and the FlashGraph format. If users provide a the text edge list format, FlashR will construct the FlashGraph format directly. e.g., both of the following commands loads the wiki-Vote graph to FlashR (assume the text edge list and the FlashGraph image are both in the current directory).
```R
g <- fg.load.graph("./wiki-Vote.txt", directed=TRUE)
g <- fg.load.graph("./wiki-Vote.adj", "./wiki-Vote.index")
```

Here shows an example of running PageRank.
```R
> library(FlashGraphR)
> fg.set.conf("flash-graph/conf/run_test.txt")
> g <- fg.load.graph("./wiki-Vote.adj", "./wiki-Vote.index")
> res <- fg.page.rank(g)
> res <- sort(as.vector(res), decreasing=FALSE, index.return=TRUE)
> tail(res$x, n=10)
 [1]  6.354546  6.411633  6.703026  7.396998  7.483035  7.702387  9.680690
 [8] 10.584648 10.879063 13.640081
> tail(res$ix, n=10)-1
 [1] 5254 7553 4191 2237 2470 2398 2625 6634   15 4037
```

## Launch FlashX Jupyter Notebook in EC2

To launch a FlashX Jupyter Notebook in EC2, a user first needs to install the boto3 library:

```
$ pip install boto3
```

Next, set up credentials (in e.g. ~/.aws/credentials):

```
[default]
aws_access_key_id = YOUR_KEY
aws_secret_access_key = YOUR_SECRET
```
After setting up boto3, a user can run the [script](https://github.com/flashxio/FlashX/blob/dev/EC2/create_instance.py) to launch a FlashX Jupyter Notebook.

```
$ python create_instance.py
```

The script will print an IP address of the EC2 instance. Access the Jupyter Notebook with "http://ec2_ip:8888".
*NOTE*: an EC2 instance may take a few minutes to fully set up. A user should wait for a few minutes to access the Notebook.
