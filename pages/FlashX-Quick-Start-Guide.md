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

# Install FlashR

FlashR is an R package. The installation steps have been tested in Ubuntu 14.04
and Ubuntu 16.04.

## Step 0: Library dependency
FlashR requires the following libraries: `libboost-dev, BLAS, libaio, libnuma, libhwloc`.
Users need to install these libraries before compiling the code of FlashX.
Among them, `libaio`, `libnuma` and `libhwloc` are optional. However, `libaio`
is required to take advantage of SSDs to scale computation to large datasets.
`libnuma` is required for machines with more than two processor sockets. `libhwloc`
is required to tune FlashR automatically to achieve the best speed for a given
hardware.

In Ubuntu, we install all tools and libraries for compiling FlashX as follows:
```
sudo apt-get update
sudo apt-get install -y g++ libboost-dev libnuma-dev libaio-dev libhwloc-dev libatlas-base-dev
```

## Step 1: install FlashR
Currently, FlashR is uploaded to a [Github](https://github.com/flashxio/FlashR) repo.
We can install FlashR in R with [devtools](https://cran.r-project.org/web/packages/devtools/index.html)
as follows.

```R
> library(devtools)
> install_github("flashxio/FlashR")
```

# Run FlashR.

FlashR is designed to optimize for different hardware. If FlashR is installed
with `libhwloc`, it adapts itself to different hardware automatically, from
a regular laptop (with a single processor) to a high-end server (with multiple
processors). For a machine with
SSDs, FlashR can utilize the SSDs to scale computation to very large datasets
if `libaio` is installed.

## Run FlashR in memory
If we run FlashR in memory and FlashR is installed with `libhwloc`, we do not
need to configure FlashR at all and all computation in FlashR is parallelized
automatically.

However, if FlashR is not installed with `libhwloc`, we still maximize
the performance of FlashR by explicitly telling FlashR the number of processors
and the number of CPU cores in the machine. We can configure FlashR with
`fm.set.conf` as follows, by passing a configuration file.
```R
> fm.set.conf("path/to/conf/file")
```

## Run FlashR with SSDs.
To run FlashR with SSDs, it is mandatory to install FlashR with `libaio`.

### Step 1: Configure SAFS
It is fairly simple to configure SAFS for a small SSD array in an SMP machine. Users only need to mount the SSDs, create data directories on SSDs and inform SAFS of the paths to the data directories. It becomes more complex to configure SAFS for a large SSD array in a NUMA machine, where we need to take processor affinity into account to maximize the performance of the SSD array. SAFS also provides a script to automate the process. To achieve the maximal performance from an SSD array, we refer users to [SAFS configurations](https://github.com/zheng-da/FlashX/wiki/SAFS-user-manual#configurations) for more details.

To run SAFS, users need to provide a data config file that indicates the paths of the data directories of SAFS. Users need to set up the SAFS parameter `root_conf` to specify the data config file. For example, if a user has two SSDs, mounted in `/mnt/ssd1` and `/mnt/ssd2`, respectively. The data config file contains two lines:
```
0:/mnt/ssd1
0:/mnt/ssd2
```
The number before ":" indicates the NUMA node Id where the SSD is attached to. For an SMP machine, the node Id is always 0.

To run FlashGraph with SAFS, we need to specify `root_conf` in the FlashGraph config file.
For the purpose of demonstration, FlashGraph provides `run_test.txt` (FlashGraph config file) and `data_files.txt` (data config file) in `flash-graph/conf/`. `data_files.txt` specifies the directory where SAFS runs. Replace `FG_TOP` in the two config files with the location of the top directory of FlashGraph.

Users have to make sure the directories in the data config file have been created. For example, if users use the example data config file `flash-graph/conf/data_files.txt`, they have to create `flash-graph/data` first.
```
mkdir flash-graph/data
```

**NOTE: users should never manually create files or directories in the data directories where SAFS runs.** Instead, users should always use `SAFS-util` to operate on SAFS.

### Step 2: Load data to SSDs
```

### Step 3: Run graph algorithms

# Run FlashR
FlashR contains functions that call graph algorithms in FlashGraph, the eigensolvers in FlashEigen and matrix operations in FlashMatrix.

## Configure FlashR
FlashR uses the same configuration file as FlashGraph. Both FlashGraph and FlashMatrix provides a default configuration file: `flash-graph/conf/run_test.txt` and `matrix/conf/run_test.txt`.

The important parameters that users need to configure for a specific machine are:
* `num_nodes`: the number of NUMA nodes that FlashR can run on.
* `threads`: the number of threads that FlashR uses.
* `root_conf`: the data config file as explained above.
In addition, users also need to specify the following parameters for FlashGraph.
* `cache_size`: the page cache size in SAFS.
* `num_io_threads`: the number of I/O threads per NUMA node.

Users can use the following function to configure FlashR.
```R
> fg.set.conf("flash-graph/conf/run_test.txt")
```

## Run FlashGraph in FlashR
Users can run graph algorithms provided by FlashGraph in FlashR.

Users can load a graph in both text edge list format and the FlashGraph format. If users provide a the text edge list format, FlashR will construct the FlashGraph format directly. e.g., both of the following commands loads the wiki-Vote graph to FlashR (assume the text edge list and the FlashGraph image are both in the current directory).
```R
g <- fg.load.graph("./wiki-Vote.txt", directed=TRUE)
g <- fg.load.graph("./wiki-Vote.adj", "./wiki-Vote.index")
```

Here shows an example of running PageRank.
```R
> library(FlashR)
> fg.set.conf("flash-graph/conf/run_test.txt")
> g <- fg.load.graph("./wiki-Vote.adj", "./wiki-Vote.index")
> res <- fg.page.rank(g)
> res <- sort(res, decreasing=FALSE, index.return=TRUE)
> tail(res$x, n=10)
 [1]  6.354546  6.411633  6.703026  7.396998  7.483035  7.702387  9.680690
 [8] 10.584648 10.879063 13.640081
> tail(res$ix, n=10)-1
 [1] 5254 7553 4191 2237 2470 2398 2625 6634   15 4037
```

## Compute eigenvalues in FlashR
There are two ways of computing eigenvalues on a large sparse graph. Users can compute eigenvalues with FlashEigen in FlashR if FlashEigen is installed. Otherwise, users can compute eigenvalues with ARPACK and FlashR for relatively smaller graphs (millions of vertices).

### Construct a sparse matrix
FlashX provides a tool called `fg2fm` to construct a sparse matrix image from a FlashGraph image. Currently, this is the only way of constructing a sparse matrix for FlashR.
```
build/matrix/utils/fg2fm matrix/conf/run_test.txt ./wiki-Vote.adj ./wiki-Vote.index wiki
```
The wiki graph is directed, so `fg2fm` outputs four files.
```
$ ls wiki*
wiki.mat  wiki.mat_idx  wiki_t.mat  wiki_t.mat_idx
```

### Load a sparse matrix in FlashR
There are multiple ways of loading a sparse matrix in FlashR.
* Users can load a graph image in FlashGraph format and get a sparse matrix.
```R
> g <- fg.load.graph("./wiki-Vote.adj", "./wiki-Vote.index")
> m <- fm.get.matrix(g)
```
* Users can load a sparse matrix image directly.
```R
> m <- fm.load.matrix("./wiki.mat", "./wiki.mat_idx", "./wiki_t.mat", "./wiki_t.mat_idx")
```

### Run FlashEigen
`fm.eigen` is the R wrapper of FlashEigen. It is designed to have a very similar interface to ARPACK in iGraph. Below shows an example of using `fm.eigen` to compute SVD on the asymmetric matrix. Currently, FlashEigen only supports computing eigenvalues on symmetric matrices.
```R
> library(FlashR)
> fg.set.conf("matrix/conf/run_test.txt")
> m <- fm.load.matrix("wiki.mat", "wiki.mat_idx", "wiki_t.mat", "wiki_t.mat_idx")
> multiply <- function(x, extra) t(m) %*% (m %*% x)
> res <- fm.eigen(multiply, options=list(n=dim(m)[1], nev=10))
> res$vals
 [1] 10647.6830  4489.1724  2999.1288  2272.7854  1608.5572  1285.5764
 [7]  1149.1096   921.1726   826.9480   758.7215
```

### Run FlashR + ARPACK
To compute eigenvalues with ARPACK and FlashR,
```R
> library(FlashR)
> fg.set.conf("matrix/conf/run_test.txt")
> m <- fm.load.matrix("wiki.mat", "wiki.mat_idx", "wiki_t.mat", "wiki_t.mat_idx")
> multiply <- function(x, extra) as.vector(t(m) %*% (m %*% fm.as.vector(x)))
> res <- arpack(multiply, sym=TRUE, options=list(n=nrow(m), nev=10, ncv=20))
> res$values
 [1] 10647.6830  4489.1724  2999.1288  2272.7854  1608.5572  1285.5764
 [7]  1149.1096   921.1726   826.9480   758.7215
```
