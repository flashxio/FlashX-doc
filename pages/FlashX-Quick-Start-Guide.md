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

Although FlashX is designed to run on top of a high-speed SSD array, it can also run on magnetic disks and completely in memory. Intuitively, FlashX runs slower on magnetic disks than on SSDs. The guide below walks you through the steps to run FlashX on a magnetic disk and completely in memory for small graphs. In the following steps, we denote the top FlashX directory as `FG_TOP` and we assume we are in the top directory throughout this guide. The steps have been tested in Ubuntu 12.04 and Ubuntu 14.04.

# Install FlashX

## Step 0: Library dependency
FlashX requires the following libraries: `libpthread, libaio, libnuma, librt, boost, libhwloc, BLAS, zlib`.
Users need to install these libraries before compiling the code of FlashX.
In Ubuntu, we install all tools and libraries for compiling FlashX as follows:
```
sudo apt-get install -y git cmake g++
sudo apt-get install -y libboost-dev libboost-system-dev libboost-filesystem-dev libnuma-dev libaio-dev libhwloc-dev libatlas-base-dev zlib1g-dev
```

## Step 1: Get FlashX's source code
Users can download FlashX's source code from [here](https://github.com/icoming/FlashX/releases) or clone it from the [github](https://github.com/icoming/FlashX.git) repository.

## Step 2: Compile FlashX
In the top directory of FlashX, run `mkdir build; cd build; cmake ../; make` to create a new directory, enter the new directory and compile all code of FlashX. If you have multiple processing cores you may prefer to run `make -j #procs`

By default, FlashEigen is disabled because it requires users to install Trilinos in advance. FlashEigen was designed to compute eigenvalues of a graph with hundreds of millions of vertices or even billions of vertices. For smaller graphs, we can use [FlashR with ARPACK](https://github.com/icoming/FlashX/wiki/Use-FlashR-with-ARPACK) to compute eigenvalues of graphs of multiple million vertices. As such, users who don't need to compute eigenvalues of very large graphs can just to Step 3.

### Step 2.1 Install Trilinos (optional)
To compile FlashX with FlashEigen, users need to install the Anasazi eigensolver in Trilinos first.
The Trilinos packages require a Fortran compiler and a BLAS and LAPACK package.

`sudo apt-get install gfortran libatlas-dev liblapack-dev`

Follow the [instructions](https://trilinos.org/oldsite/TrilinosBuildQuickRef.html#configuring-makefile-generator) in Trilinos' website to compile it. Here summaries the steps:

Inside the top directory of the Trilinos source code, create the following script named `do-configure`:
```
#!/bin/sh
EXTRA_ARGS=$@
SOURCE_BASE=..
cmake \
    -D CMAKE_BUILD_TYPE:STRING=RELEASE \
    -D BUILD_SHARED_LIBS:BOOL=ON \
    -D Trilinos_ENABLE_TESTS=OFF \
    $EXTRA_ARGS \
    ${SOURCE_BASE}
```

Make the script executable.
`chmod u+x do-configure`

Create a directory named `build` in the top directory and compile the Trilinos source code in the build directory.
```
mkdir build
cd build/
../do-configure -DTrilinos_ENABLE_Anasazi=ON
make -j32
make install
```

### Step 2.2: compile FlashX with FlashEigen (optional)
In the top directory of FlashX, run `mkdir build; cd build; cmake -D ENABLE_TRILINOS:BOOL=ON ..; make`

## Step 3: compile and install FlashR

If users don't have R installed, they can follow the [instruction](https://cran.r-project.org/bin/linux/ubuntu/README) to install R in Ubuntu.

`sudo apt-get install r-base-dev`

FlashR requires igraph and Rcpp packages. Before installing FlashR, a user needs to install igraph, which installs the Rcpp package automatically. Users should install the latest R in order to install igraph. In the R environment, run

`> install.packages("igraph")`

In the top directory of FlashX, run `./install_FlashR.sh` to install FlashR. The script tests if FlashEigen is compiled in Step 2. If FlashEigen is compiled, the script will compile FlashR with FlashEigen automatically.

# Install FlashX in docker
We prepare a docker file for users to install FlashX in docker easily, by simply following the two steps below. The following docker file builds all components in FlashX but doesn't build FlashX with Trilinos.

```
git clone https://github.com/zheng-da/FlashxStuff.git
docker build -t flashx FlashxStuff/
```
For default, the docker file compiles FlashX source code with 4 processes. If users' platforms have many more CPU cores, they can utilize more CPU cores to accelerate the complication of FlashX. For example, if a user's platform has 32 CPU cores, he can modify line 40 in `FlashxStuff/Dockerfile` to `RUN make -j32` before building the docker image.

To run the docker image, users can simply run `docker run -t -i flashx /bin/bash`.

# Run FlashGraph
FlashGraph can run both in memory and on SSDs.

## Convert a graph in edge list format to the FlashGraph format

To run FlashGraph, users need to construct a graph in the FlashGraph format. We demonstrate the process with graphs from Stanford's [SNAP](http://snap.stanford.edu/data/) project. We currently require the input graph to be in **edge list text format**.

Go to the top directory of FlashX and download a graph from the SNAP website.

` wget http://snap.stanford.edu/data/wiki-Vote.txt.gz`

FlashX provides a tool `el2fg` to convert an edge list file in text format to the graph format supported by FlashGraph.
```
gunzip wiki-Vote.txt.gz
build/matrix/utils/el2fg flash-graph/conf/run_test.txt wiki-Vote.txt wiki-Vote
```

This tool takes a configuration file, a graph file in text edge list and a user-specified graph name. The command above creates two files `wiki-Vote.adj` and `wiki-Vote.index`.
For the purpose of demonstration, FlashGraph provides `flash-graph/conf/run_test.txt`. The details on the configuration file can be found [here](https://github.com/icoming/FlashGraph/wiki/FlashGraph-tutorial#flashgraph-configuration-parameters).

The FlashGraph format allows one attribute for an edge. To construct a graph with edge attributes, users need to provide option `-t` to indicate the attribute type ("I" for 32-bytes integers, "L" for 64-bits integers, "F" for single-precision floating point, "D" for double-precision floating point). The command below shows an example of converting a graph with integer edge attributes.
```
build/matrix/utils/el2fg flash-graph/conf/run_test.txt graph_edgelist.txt graph_name -t I
```

## Run FlashGraph in the standalone mode
Although FlashGraph is designed to work with SAFS, it can also run in the standalone mode. In this mode, FlashGraph loads graphs in memory and perform computation on the in-memory graphs. This is the simplest setup for FlashGraph. This mode detects the number of CPU cores and runs in parallel automatically.

FlashGraph provides a few built-in graph algorithm implementations. Users can run these implementations in flash-graph/test-algs/test_algs. test_algs takes three arguments: a FlashGraph config file, a graph file of the FlashGraph format and an index file for the graph file from the local Linux filesystem.
For example, the command below runs WCC (weakly connected components) on the wiki graph.
```
build/flash-graph/test-algs/test_algs flash-graph/conf/run_test.txt wiki-Vote.adj wiki-Vote.index wcc
...
There are 1183 empty vertices
There are 24 components (exclude empty vertices), and largest comp has 7066 vertices
```

## Run FlashGraph with SAFS.
FlashGraph is designed to run with SAFS, so that it can run on top of an SSD array. When running FlashGraph with SAFS, we get the full power of FlashGraph. It requires us to configure SAFS properly.

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

### Step 2: Load graph files to SAFS
We need to load a graph to SAFS before we run FlashGraph.

If a user has a graph in the FlashGraph format, we load a file from a Linux filesystem to SAFS with `SAFS-util`. The following commands load the wiki-Vote graph to SAFS. When loading graph files to SAFS, the recommended naming convention is that for a graph named `graph_name`, the graph file should be named with `graph_name.adj` and the index file should be named with `graph_name.index`. This naming convention is important when users run FlashGraph in R.
```
build/utils/SAFS-util flash-graph/conf/run_test.txt load wiki-Vote.adj wiki-Vote.adj
build/utils/SAFS-util flash-graph/conf/run_test.txt load wiki-Vote.index wiki-Vote.index
```

If a user has a graph in the text format, we can construct a graph and store it on SAFS directly with `el2al`.
```
build/matrix/utils/el2fg -e flash-graph/conf/run_test.txt wiki-Vote.txt wiki-Vote
```

### Step 3: Run graph algorithms
The command below demonstrates how to run PageRank on wiki-Vote.
```
build/flash-graph/test-algs/test_algs flash-graph/conf/run_test.txt wiki-Vote.adj wiki-Vote.index pagerank2
...
The sum of pagerank of all vertices: 3146.831787
v5254: 6.384571
v7553: 6.444084
v4191: 6.734981
v2237: 7.413904
v2470: 7.496633
v2398: 7.745999
v2625: 9.750073
v6634: 10.646951
v15: 10.923159
v4037: 13.684291
```

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
