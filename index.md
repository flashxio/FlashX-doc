---
title: The FlashX Documentation
keywords: sample homepage
tags: [getting_started]
sidebar: mydoc_sidebar
permalink: index.html
summary:
---

FlashX performs data analytics in the form of graphs and matrices. It runs
on a variety of hardware and can utilize solid-state drives (SSDs) to scale
to large datasets in a single machine. The goal of FlashX is to process massive
datasets with extreme efficiency in a single machine. Right now, FlashX
provides the R programming interface.

FlashX has three main components:

* FlashGraph is a general-purpose programming framework with a vertex-centric
programming interface for large-scale graph analysis. FlashGraph is able to
scale to billion-node graphs in a single machine and significantly outperforms
state-of-art distributed graph analysis frameworks at this scale.
* FlashMatrix is a matrix computation engine that provides generalized matrix
operations (GenOps). FlashMatrix uses a small set of GenOps to support a large
variety of matrix operations and express varieties of data mining and machine
learning algorithms. It keeps matrices on SSDs to scale to very large datasets.
* FlashR reimplements matrix operations in the R framework with GenOps of
FlashMatrix. With the help of FlashR, R users can execute existing R code to
process datasets at a scale of terabytes with the speed of optimized parallel C
code.

![Architecture](https://flashxio.github.io/FlashX-doc/images/arch.jpg)

# [Quick Start](https://flashxio.github.io/FlashX-doc/FlashX-Quick-Start-Guide.html)

We provide instructions to install FlashX and use some simple examples to show how to use FlashR for computation.

# [User Guide](https://flashxio.github.io/FlashX-doc/FlashMatrix-user-guide.html)

This documentation provides detailed description of the FlashR functions.

# Tutorials

This lists specific applications and shows how to solve them with FlashX.

# [Contributing](https://flashxio.github.io/FlashX-doc/Contributing.html)

# API
