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
$ sudo apt-get install -y g++ libboost-dev libnuma-dev libaio-dev libhwloc-dev libatlas-base-dev
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
with `root_conf` in the configuration file. `root_conf` accepts the path to
a text file or to a directory. If a machine has only one SSD or multiple SSDs
connected with a RAID controller, we can create a directory on the SSD(s),
and give the path to `root_conf`. Please check [here]() for more advanced configuration
of a large SSD array on a large parallel machine.

** NOTE: to run FlashR with SSDs, it is mandatory to install FlashR with `libaio`.**

### Run an example in FlashR
