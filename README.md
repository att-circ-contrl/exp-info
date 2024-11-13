# Signal Entropy and Connectivity Analysis Library

## Overview

This is a set of libraries written to support the analysis of entropy-based
information content of neural signals and of connectivity and communication
between channels in neural recordings.

At present, this is a private project, but it is intended to be released
under an open source license at a later time.


## Documentation

The following files and directories contain documentation:

* The `manuals` directory contains PDF documentation files produced by
the sources described below.
* The `manual-src` directory is the LaTeX build directory for project-wide
documentation. Use `make -C manual-src` to rebuild these documents.


## Libraries

Libraries are provided in the `libraries` directory. With that directory
on path, call the `addPathsExpInfo` function to add sub-folders.

The following subdirectories contain library code:

* `lib-expinfo-aux` --
Additional functions that don't fit into any of the other categories.
* `lib-expinfo-calc` --
Calculation of various information measures. Requires the entropy library.
* `lib-expinfo-plot` --
Plotting functions for script development and testing. These plots are not
publication-quality.


## Sample Code

Interim example code is in the `exp-info-examples` GitHub repository.



*(This is the end of the file.)*
