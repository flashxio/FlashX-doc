---
title: The FlashMatrix User Guide
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "The FlashMatrix User Guide"
sidebar: mydoc_sidebar
permalink: FlashMatrix-user-guide.html
folder: mydoc
---

FlashMatrix is a matrix computation engine that provides a small set of generalized matrix operations (GenOps) to express varieties of data mining and machine learning algorithms. It scales to very large datasets by storing matrices on SSDs. It is created as the backend of FlashR but users can program on it directly. FlashMatrix executes the GenOps in parallel and out of core automatically to hide the complexity of parallelization and data access to SSDs. The current implementation of FlashMatrix supports GenOps on dense matrices.

The main programming interface of FlashMatrix is defined in the `dense_matrix` class. `dense_matrix` is immutable and every computation outputs a new matrix.

```C++
class dense_matrix
{
// Create a dense matrix. Users can specify the size (nrow, ncol), the data layout
// (layout: row-major or column-major), the element type (type), the storage
// (num_nodes, in_mem: SMP memory, NUMA memory and disks) and data filled in the matrix.
// Create a dense matrix with data defined by users.
static ptr create(size_t nrow, size_t ncol, matrix_layout_t layout,
const scalar_type &type, const set_operate &op, int num_nodes = -1,
bool in_mem = true, safs::safs_file_group::ptr group = NULL);
// Create a dense matrix with data generated uniformly randomly between min and max.
template<class T>
static ptr create_randu(T min, T max, size_t nrow, size_t ncol,
matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
safs::safs_file_group::ptr group = NULL);
// Create a dense matrix with data generated under normal random distribution.
template<class T>
static ptr create_randn(T mean, T var, size_t nrow, size_t ncol,
matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
safs::safs_file_group::ptr group = NULL);
// Create a dense matrix filled with the same value.
template<class T>
static ptr create_const(T val, size_t nrow, size_t ncol,
matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
safs::safs_file_group::ptr group = NULL);

// Get rows/columns of the matrix.
dense_matrix::ptr get_cols(const std::vector<off_t> &idxs) const;
dense_matrix::ptr get_rows(const std::vector<off_t> &idxs) const;

// Create a transpose of the matrix.
dense_matrix::ptr transpose() const;

// Compute inner product of the matrix with another matrix.
dense_matrix::ptr inner_prod(const dense_matrix &m,
bulk_operate::const_ptr left_op, bulk_operate::const_ptr right_op,
matrix_layout_t out_layout = matrix_layout_t::L_NONE) const;
// Matrix multiplication. It's a special case of inner product.
// For floating-point matrices (float or double), it calls BLAS for matrix multiplication.
dense_matrix::ptr multiply(const dense_matrix &mat,
matrix_layout_t out_layout = matrix_layout_t::L_NONE,
bool use_blas = false) const;

// Perform aggregation on the matrix.
// There are three variants: aggregate on the entire matrix and outputs a scalar.
// aggregate on the rows of the matrix and output a vector.
// aggregate on the columns of the matrix and output a vector.
vector::ptr aggregate(matrix_margin margin, agg_operate::const_ptr op) const;
// Aggregate on the entire matrix.
std::shared_ptr<scalar_variable> aggregate(agg_operate::const_ptr op) const;
std::shared_ptr<scalar_variable> aggregate(bulk_operate::const_ptr op) const;

// Group rows based on their labels and perform aggregation on the rows in each group.
dense_matrix::ptr groupby_row(factor_vector::const_ptr labels,
agg_operate::const_ptr) const;
dense_matrix::ptr groupby_row(factor_vector::const_ptr labels,
bulk_operate::const_ptr) const;

// Perform element-wise operations. There are four variants.
// Perform element-wise operations on every column of the matrix with a vector.
dense_matrix::ptr mapply_cols(std::shared_ptr<const vector> vals,
bulk_operate::const_ptr op) const;
// Perform element-wise operations on every row of the matrix with a vector.
dense_matrix::ptr mapply_rows(std::shared_ptr<const vector> vals,
bulk_operate::const_ptr op) const;
// Perform element-wise operations on the two matrices.
dense_matrix::ptr mapply2(const dense_matrix &m,
bulk_operate::const_ptr op) const;
// Perform element-wise operations on the matrix
dense_matrix::ptr sapply(bulk_uoperate::const_ptr op) const;
};
```

A few classes related to `dense_matrix`:

* `scalar_type` defines the element type of a matrix. It actually defines the storage size of an element and the operations on the elements. Users can get `scalar_type` with the template `get_scalar_type<T>()`.
* `bulk_operate` defines a vectorized binary operation. Users can access the set of built-in binary operations in FlashMatrix from `get_scalar_type<T>().get_basic_ops().get_op(idx)`. Users can also define their own `bulk_operate`.
* `bulk_uoperate` defines a set of unary operations. Similar to `bulk_operate`, users can access the set of built-in unary operations from `get_scalar_type<T>().get_basic_uops().get_op(idx)` and define their own operations.
* `agg_operate` defines the aggregation operations. Users can create an `agg_operate` object with `agg_operate::create` with `bulk_operate`.

