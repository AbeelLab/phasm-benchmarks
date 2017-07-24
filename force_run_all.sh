#!/bin/sh
#SBATCH --partition=bigmem
#SBATCH --qos=bigmem
#SBATCH --time=6-23:59:59
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --mail-type=ALL
#SBATCH --workdir=/tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/phasm-benchmarks

rm -rf /tmp/lrvandijk/phasm-benchmarks
mkdir -p /tmp/lrvandijk/phasm-benchmarks
cp -r * /tmp/lrvandijk/phasm-benchmarks
cd /tmp/lrvandijk/phasm-benchmarks

snakemake --keep-going --cores=16 all_genomes
snakemake --keep-going --cores=16 all_errorfree_readsets
snakemake --keep-going --cores=16 all

rm -rf /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/last_benchmark/*
cp -r * /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/last_benchmark
