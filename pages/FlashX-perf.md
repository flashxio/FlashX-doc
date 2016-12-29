---
title: The performance of FlashX
keywords: performance
last_updated: Dec 28, 2016
tags: [performance]
summary: "The performance of FlashX"
sidebar: mydoc_sidebar
permalink: FlashX-perf.html
folder: mydoc
---

#FlashGraph performance

FlashGraph was designed for specialized hardware (a large parallel machine with many SSDs).
However, most people may not possess such powerful hardware, so we also evaluate its performance in the Amazon cloud. Table 1 shows the hardware configurations where FlashGraph is evaluated. We demonstrate that FlashGraph is able to outperform other well-known graph processing frameworks in both specialized hardware and Amazon cloud.

|            | i2.xlarge | i2.8xlarge | HW1    | HW2    |
| ---------- |:---------:| ----------:|-------:|-------:|
| #CPU cores | 4         | 32         | 32     | 48     |
| RAM (GB)   | 30        | 244        | 512    | 1024   |
| #SSDs      | 1         | 8          | 15     | 24     |
Table 1. The hardware configuration where FlashGraph is evaluated.

|          | i2.xlarge | i2.8xlarge | HW1    | HW2    |
| -------- |:---------:| ----------:|-------:|-------:|
| BFS      | 36.86     | 5.48       | 3.56   | 3.11   |
| PageRank | 438.74    | 67.34      | 54.07  | 33.58  |
| WCC      | 58.90     | 7.91       | 7.91   | 5.03   |
| Triangle | 4747.07   | 830.08     | 532.21 | 442.65 |
| SCC      | 141.62    | 22.39      | N/A    | 12.06  |
Table 2. The runtime (seconds) of FlashGraph on different hardware with 1GB page cache.

We evaluate the performance of FlashGraph on the Twitter graph with 42 millions vertices and 1.5 billion edges (Table 2). The reason that we choose the Twitter graph is that this graph is used by many graph processing frameworks for performance evaluation. We run multiple graph algorithms: breadth-first search, triangle counting, weakly connected components and pagerank.
The twitter graph is relatively small and all of the hardware has enough RAM to keep the entire graph in memory. We artificially limit the page cache size in FlashGraph to 1GB and 4GB to push most of data access to SSDs. As a result, FlashGraph only uses a small fraction of the RAM in the machines. Keep in mind that FlashGraph runs much faster if we do not limit its page cache size. To our surprise, the i2.8xlarge instance has performance very close to our specialized hardware.

For comparison, we pull performance results of distributed graph engines from the [GraphX paper](https://amplab.cs.berkeley.edu/wp-content/uploads/2014/09/graphx.pdf). The paper don't have performance results of all of the graph applications we evaluated. Therefore, we only compare their performance in PageRank and weakly connected components. [Giraph](http://giraph.apache.org/), [GraphX](http://spark.apache.org/graphx/) and [PowerGraph](https://github.com/dato-code/PowerGraph) were evaluated in 16 m2.4xlarge instances, which each has 8 CPU cores and 68GB RAM. Only PowerGraph is a little faster than FlashGraph in PageRank when FlashGraph runs in a small Amazon instance.

![runtime](http://flashx.io/images/FlashGraph.vs.others.png)

Figure 1. The runtime of FlashGraph vs. distributed graph engines in PageRank and weakly connected components.

Given such performance results, we can further demonstrate that FlashGraph is much more economical than distributed graph engines in the Amazon cloud. m2.4xlarge is the previous-generation instance type. A similar instance (m4.2xlarge) of the current generation has cut the price almost by half and we use the cost of m4.2xlarge for the calculation. Figure 2 shows the runtime dollars (=runtime * instance cost) of the graph engines in the cloud. When comparing these graph engines with this metric, FlashGraph in i2.xlarge is the most economical. These distributed graph engines are one order of magnitude more costly than FlashGraph in the cloud.

![runtime dollors](http://flashx.io/images/FlashGraph.vs.others.dollor.png)

Figure 2. The runtime dollars of FlashGraph vs. distributed graph engines.

# FlashR performance
FlashR provides [R matrix operations](https://github.com/zheng-da/FlashX/wiki/FlashR-programming-tutorial#base-r-functions) for users to express data analysis algorithms and is able to execute them both in memory and on SSDs. We evaluates the performance of these dense matrix operations with five statistics and machine learning algorithms: statistics summary, correlation, SVD, k-means, GMM, completely implemented in R. We compare these implementations with the ones in the R framework and Spark MLlib. The implementations in the R framework is written in C/FORTRAN and can only run in a single thread. As such, for a fair comparison, we run the FlashR implementations in a single thread when comparing with the C/FORTRAN implementations in the R framework. We evaluate the implementations in machine HW2.

The FlashR implementations outperform the ones in R even with a single thread (Figure 3) and outperform the ones in Spark MLlib by almost an order of magnitude in the parallel machine (Figure 4). Furthermore, FlashR supports both in-memory and external-memory execution. Given fast SSDs, FlashR executes these implementations on SSDs with the speed comparable to in-memory execution. Given the small memory consumption of FlashR in the external-memory mode (Figure 5), we demonstrate that FlashR can scale to very large datasets easily.

![runtime of FlashR vs. R](http://flashx.io/images/FlashR.vs.R.png)

Figure 3. The runtime of FlashR vs. R in a single thread on a dataset with 65 million data points and 32 features.

![runtime of FlashR vs. Spark MLlib](http://flashx.io/images/FlashR.vs.MLlib.png)

Figure 4. The runtime of FlashR vs. Spark MLlib in a large parallel machine with 48 CPU cores on a dataset with 1 billion data points and 32 features..

![Memory consumption of FlashR vs. Spark MLlib](http://flashx.io/images/FlashR.vs.MLlib.mem.png)

Figure 5. The memory consumption of FlashR vs. Spark MLlib on a dataset with 1 billion data points and 32 features.

# FlashGraph scalability

FlashGraph enables us to process very large graphs in a single machine. Here we demonstrate that FlashGraph can process a real-world [hyperlink page graph](http://webdatacommons.org/hyperlinkgraph/) (3.4B vertices and 129B edges) in a single machine. The table below shows the performance of the same graph applications as above. It also includes the performance of Betweenness centrality (BC) from a single vertex.

|             | Runtime (sec) | Memory (GB) |
| ----------- |:-------------:| -----------:|
| BFS         | 298           | 22          |
| Betweenness | 595           | 81          |
| Triangle    | 7818          | 55          |
| WCC         | 461           | 47          |
| PageRank    | 2041          | 46          |
Table 3. The runtime of FlashGraph on the Page graph on HW1.

FlashGraph takes only six minutes to traverse the page graph (3.5B vertices and 128B edges) with a cache size of 4GB.
[Pregel](http://dl.acm.org/citation.cfm?id=1807184) used 300 multicore machines to
run the shortest path algorithm on their largest random graph (1B vertices and 127B edges)
and took a little over ten minutes. More recently,
[Trinity](http://research.microsoft.com/en-us/projects/trinity/)
took over ten minutes to perform breadth-first search on a
graph of one billion vertices and 13 billion edges on 14 12-core
machines.

FlashGraph takes 34 minutes to run 30 iterations of PageRank on the page graph. Based on a recent talk by the main developer of [Giraph](http://www.youtube.com/watch?v=b5Qmz4zPj-M), Giraph running with 20 workers can run five iterations of PageRank on a graph with 5 billion edges in approx. 75 minutes.
