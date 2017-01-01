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

FlashMatrix is a matrix computation engine that provides a small set of
generalized matrix operations (GenOps) to express varieties of data mining
and machine learning algorithms. It scales to very large datasets by storing
matrices on SSDs. FlashMatrix performs computation in the GenOps in parallel
and out of core automatically to hide the complexity of parallelization and
data access to SSDs. The GenOps provide very high expressiveness for the framework.

FlashMatrix does not store data of most matrices physically in memory or on
disks. Instead, most of the matrix computations in FlashMatrix output virtual
matrices that only store the computation and the input matrices for
the computation if necessary. As such, when performing a sequence of matrix
operations, FlashMatrix constructs a DAG (directed acyclic graph) to represent
the sequence of operations. We can explicitly materialize the computation in
a DAG when we need the computation result.

Although FlashMatrix is created as the backend of FlashR, users can program on
it directly. FlashMatrix is implemented in C++. As such, users write programs
with its C++ programming interface. Thanks to the flexibility of C++,
the C++ interface of FlashMatrix is much more flexible than the R interface of
FlashR.

## Dense matrices

The main programming interface of FlashMatrix is defined in the `dense_matrix`
class. `dense_matrix` is immutable and every computation outputs a new matrix.

### Construction of dense matrices

`dense_matrix` defines a few constructors to create a dense matrix. Other than
the dimension size (the number of rows and columns), users can specify the data layout
(row major or column major), the element type (integer, double floating-point, etc)
and memory storage media (SMP memory, NUMA memory or disks). In addition,
users can also specify which matrices are grouped together when they are
stored on disks. The following constructors differ in values defined in a matrix.

```cpp
// This constructor creates a matrix with user-defined data.
dense_matrix::ptr dense_matrix::create(size_t nrow, size_t ncol, matrix_layout_t layout,
		const scalar_type &type, const set_operate &op, int num_nodes = -1, bool in_mem = true,
		safs::safs_file_group::ptr group = NULL);

// Create a dense matrix with data generated uniformly randomly between min and max.
template<class T>
dense_matrix::ptr dense_matrix::create_randu(T min, T max, size_t nrow, size_t ncol,
		matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
		safs::safs_file_group::ptr group = NULL);

// Create a dense matrix with data generated under normal random distribution.
template<class T>
dense_matrix::ptr dense_matrix::create_randn(T mean, T var, size_t nrow, size_t ncol,
		matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
		safs::safs_file_group::ptr group = NULL);

// Create a dense matrix filled with the same value.
template<class T>
dense_matrix::ptr dense_matrix::create_const(T val, size_t nrow, size_t ncol,
		matrix_layout_t layout, int num_nodes = -1, bool in_mem = true,
		safs::safs_file_group::ptr group = NULL);

// Create a dense matrix filled with sequence numbers.
template<class T>
dense_matrix::ptr dense_matrix::create_seq(T start, T stride, size_t nrow, size_t ncol,
		matrix_layout_t layout, bool byrow, int num_nodes = -1, bool in_mem = true,
		safs::safs_file_group::ptr group = NULL);

```

### GenOps

Here lists the generalized matrix operations (GenOps) provided by FlashMatrix.
There are four types of GenOps. Some of the GenOps have multiple variants.

* inner product
* aggregation
* groupby
* element-wise operations.

All of the GenOps output a new matrix represented by a virtual matrix.

```cpp
// Compute inner product of the matrix with another matrix.
dense_matrix::ptr dense_matrix::inner_prod(const dense_matrix &m,
		bulk_operate::const_ptr left_op, bulk_operate::const_ptr right_op,
		matrix_layout_t out_layout = matrix_layout_t::L_NONE) const;
// Matrix multiplication. It's a special case of inner product.
// For floating-point matrices (float or double), it calls BLAS for matrix multiplication.
dense_matrix::ptr dense_matrix::multiply(const dense_matrix &mat,
		matrix_layout_t out_layout = matrix_layout_t::L_NONE,
		bool use_blas = false) const;

// Perform aggregation on the matrix.
// There are three variants: aggregate on the entire matrix and outputs a scalar.
// aggregate on the rows of the matrix and output a vector.
// aggregate on the columns of the matrix and output a vector.
vector::ptr dense_matrix::aggregate(matrix_margin margin, agg_operate::const_ptr op) const;
// Aggregate on the entire matrix.
std::shared_ptr<scalar_variable> dense_matrix::aggregate(agg_operate::const_ptr op) const;
std::shared_ptr<scalar_variable> dense_matrix::aggregate(bulk_operate::const_ptr op) const;

// Group rows based on their labels and perform aggregation on the rows in each group.
dense_matrix::ptr dense_matrix::groupby_row(factor_col_vector::const_ptr labels,
		agg_operate::const_ptr) const;
dense_matrix::ptr dense_matrix::groupby_row(factor_col_vector::const_ptr labels,
		bulk_operate::const_ptr) const;

// Perform element-wise operations. There are four variants.
// Perform element-wise operations on every column of the matrix with a vector.
dense_matrix::ptr dense_matrix::mapply_cols(col_vector::const_ptr vals,
		bulk_operate::const_ptr op) const;
// Perform element-wise operations on every row of the matrix with a vector.
dense_matrix::ptr dense_matrix::mapply_rows(vector::const_ptr vals,
		bulk_operate::const_ptr op) const;
// Perform element-wise operations on the two matrices.
dense_matrix::ptr dense_matrix::mapply2(const dense_matrix &m,
		bulk_operate::const_ptr op) const;
// Perform element-wise operations on the matrix
dense_matrix::ptr dense_matrix::sapply(bulk_uoperate::const_ptr op) const;
```

### Misc

In addition to the GenOps, `dense_matrix` provides some utility functions to
get rows/columns from a matrix, convert the data layout and construct
the transpose of the matrix. Like the GenOps, most of the operations are also
virtualized, i.e., the operations aren't performed in the place where
the functions are invoked.

```cpp
// Get a small number of rows/columns from the matrix.
dense_matrix::ptr dense_matrix::get_cols(const std::vector<off_t> &idxs) const;
dense_matrix::ptr dense_matrix::get_rows(const std::vector<off_t> &idxs) const;

// Get a large number of rows/columns from the matrix.
dense_matrix::ptr dense_matrix::get_cols(col_vec::ptr idxs) const;
dense_matrix::ptr dense_matrix::get_rows(col_vec::ptr idxs) const;

// Convert the data layout of the matrix.
dense_matrix::ptr dense_matrix::conv2(matrix_layout_t layout) const;

// Create a transpose of the matrix.
dense_matrix::ptr dense_matrix::transpose() const;
```

### Matrix materialization

FlashMatrix provides multiple functions to force matrix materialization.
`dense_matrix` has two methods to materialize a dense matrix: `conv_store`
and `materialize_self`. In addition, FlashMatrix provides a function `materialize`
to materialize a list of virtual matrices.

```cpp
// Convert the storage media of the matrix. If this matrix is a virtual matrix,
// this method stores the computation result in the specified memory media.
dense_matrix::ptr dense_matrix::conv_store(bool in_mem, int num_nodes) const;

// Materialize the computation in the matrix.
bool dense_matrix::materialize_self() const;

// Materialize a list of virtual matrices.
bool materialize(std::vector<std::shared_ptr<dense_matrix> > &mats,
		bool par_access = true);
```

In addition to the functions for explicit matrix materialization, `dense_matrix`
also provides a method `set_materialize_level` to notify FlashMatrix of saving
the computation result in a virtual matrices in a DAG, even if the virtual matrix
isn't explicitly materialized. Currently, there are two materialization levels:
`MATER_CPU`, `MATER_MEM` and `MATER_FULL`. `MATER_CPU` means materialization of
a partition of a matrix in the CPU cache;  `MATER_MEM` means materialization of
a partition in memory; `MATER_FULL` means to save the materialization result of
the entire matrix. Currently, only `MATER_CPU` and `MATER_FULL` are used and
the default level is `MATER_CPU`.

```cpp

void dense_matrix::set_materialize_level(materialize_level level,
		detail::matrix_store::ptr materialize_buf = NULL);
```

## Vectors

FlashMatrix uses `col_vec`, a single-column matrix, to represent a vector.
`col_vec` is inherited from `dense_matrix`. As such, it has all methods
of `dense_matrix`.

`factor_col_vector` is a special single-column matrix. It stores categorical
values and is mainly used with `groupby_row` in `dense_matrix`.

## Related classes
FlashMatrix defines multiple related classes. `scalar_type` represents
the element type of a matrix. `bulk_operate`, `bulk_uoperate` and `agg_operate`
defines matrix element operations. FlashMatrix provides many predefined matrix
element types and element operations. Users can also inherit these classes to
define new element types and element operations.

* `scalar_type` defines the element type of a matrix. It actually defines the storage size of an element and the operations on the elements. Users can get `scalar_type` with the template `get_scalar_type<T>()`.
* `bulk_operate` defines a vectorized binary operation. Users can access the set of built-in binary operations in FlashMatrix from `get_scalar_type<T>().get_basic_ops().get_op(idx)`. Users can also define their own `bulk_operate`.
* `bulk_uoperate` defines a set of unary operations. Similar to `bulk_operate`, users can access the set of built-in unary operations from `get_scalar_type<T>().get_basic_uops().get_op(idx)` and define their own operations.
* `agg_operate` defines the aggregation operations. Users can create an `agg_operate` object with `agg_operate::create` with `bulk_operate`.
