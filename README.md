PHASM Benchmarks
================

[![Snakemake](https://img.shields.io/badge/snakemake-≥3.11-brightgreen.svg?style=flat-square)](https://snakemake.bitbucket.io)

This repository contains a [snakemake][snakemake] pipeline that runs the 
[PHASM][phasm] *de novo* genome assembler for several synthetic genomes.
Using the provides Conda environment file is the easiest way to install all 
dependencies.

Requirements
------------

* Python >= 3.5
* Snakemake >= 3.11
* DAZZ_DB / DALIGNER
* NumPy
* SciPy
* Pandas
* matplotlib
* networkx
* samtools
* pysam
* simlord

Installation and running
------------------------

Clone the repository, and move into that directory. Then create the conda 
environment and run the pipeline.

    conda env create -f environment.yml
    source activate phasm

    # Run the whole pipeline
    snakemake --cores all

Related Repositories
--------------------

* [PHASM][phasm]
* [aneusim][aneusim]

[phasm]: https://github.com/lrvdijk/phasm
[aneusim]: https://github.com/lrvdijk/aneusim
[snakemake]: https://bitbucket.org/snakemake/snakemake
