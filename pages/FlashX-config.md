---
title: Configure FlashX
keywords: tutorial
last_updated: Jan 18, 2017
tags: [tutorial]
summary: "Configure FlashX"
sidebar: mydoc_sidebar
permalink: FlashX-config.html
folder: mydoc
---

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
