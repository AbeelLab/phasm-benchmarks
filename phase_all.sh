#!/bin/sh
#SBATCH --partition=bigmem
#SBATCH --qos=bigmem
#SBATCH --time=23:59:59
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --mail-type=ALL
#SBATCH --workdir=/tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/phasm-benchmarks

rm -rf /tmp/lrvandijk/phasm-benchmarks
mkdir -p /tmp/lrvandijk/phasm-benchmarks
cp -r * /tmp/lrvandijk/phasm-benchmarks
cd /tmp/lrvandijk/phasm-benchmarks

srun snakemake --cores=16 all

cp -r reads/ assemblies/ /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/phasm-benchmarks
