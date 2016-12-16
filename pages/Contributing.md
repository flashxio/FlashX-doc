---
title: How to contribute to FlashX
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "How to contribute to FlashX"
sidebar: mydoc_sidebar
permalink: Contributing.html
folder: mydoc
---

TODO list for the R interface

* Port R packages ([MASS](https://cran.r-project.org/web/packages/MASS/index.html), [e1071](https://cran.r-project.org/web/packages/e1071/index.html), [caret](http://topepo.github.io/caret/index.html), [NMF](https://cran.r-project.org/web/packages/NMF/index.html)) to FlashR.
* Implement [dplyr](https://cran.r-project.org/web/packages/dplyr/index.html).
* Implement and port [mclust](https://cran.r-project.org/web/packages/mclust/index.html)

TODO list for the Python interface

* Implement [NumPy](http://www.numpy.org/) interface with FlashMatrix.
* Port [SciPy](https://www.scipy.org/), [scikit-learn](http://scikit-learn.org/) and [pandas](http://pandas.pydata.org/) to FlashX.

TODO list for additional graph analysis algorithms

* Louvain clustering
* very efficient shortest path search

TODO list for additional machine learning algorithms

* SVM
* elastic nets
* random forest
* gradient boosting
* isomap and many other manifold learning algorithms

Explore more advanced/experimental machine learning algorithms

* Randomized algorithms: Although FlashX supports very large datasets by storing data on SSDs, the computation or the I/O bandwidth from SSDs to CPU might still be the bottleneck. Randomized algorithms can help us to reduce computation or data movement or both to significantly achieve performance while retaining similar accuracy. Examples are random SVD and randomized Newton method.

TODO list for the FlashX framework

* Implement an R compiler to translate the R code in user-defined functions passed to generalized matrix operations.
The generalized matrix operations require user-defined functions to perform actual matrix computation on matrices. Currently, the user-defined functions have to be implemented in C++. We need to allow users to implement the user-defined functions in R and compile them into low-level representations that run in the underlying system of FlashR. The goal is to improve generality of the FlashR framework and still achieve very high performance (close to the efficient C implementations).
* Test FlashX on different Linux distributions.
* Port FlashX to Mac and Windows.
