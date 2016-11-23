---
title: Compile FlashX with the Anasazi package
keywords: tutorial
last_updated: Nov 3, 2016
tags: [tutorial]
summary: "Compile FlashX with the Anasazi package"
sidebar: mydoc_sidebar
permalink: FlashX-with-anasazi.html
folder: mydoc
---

## Install Trilinos
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

## compile FlashX with FlashEigen
In the top directory of FlashX, run `mkdir build; cd build; cmake -D ENABLE_TRILINOS:BOOL=ON ..; make`
