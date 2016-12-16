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
* Port R packages (MASS, e1071 and caret) to FlashR.

TODO list for the Python interface
* Implement NumPy interface with FlashMatrix.
* Port SciPy, scikit-learn and pandas to FlashX.

Additional machine learning algorithms
* SVM
* random forest
* gradient boosting

Explore more advanced/experimental machine learning algorithms
* Randomized algorithms: Although FlashX supports very large datasets by storing data on SSDs, the computation or the I/O bandwidth from SSDs to CPU might still be the bottleneck. Randomized algorithms can help us to reduce computation or data movement or both to significantly achieve performance while retaining similar accuracy. Examples are random SVD and randomized Newton method.

Implement an R compiler to translate the R code in user-defined functions passed to generalized matrix operations.
The generalized matrix operations require user-defined functions to perform actual matrix computation on matrices. Currently, the user-defined functions have to be implemented in C++. We need to allow users to implement the user-defined functions in R and compile them into low-level representations that run in the underlying system of FlashR. The goal is to improve generality of the FlashR framework and still achieve very high performance (close to the efficient C implementations).

