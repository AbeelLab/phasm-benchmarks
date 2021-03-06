import yaml

with open("config.yml") as f:
    config = yaml.load(f)

TEMPLATE = """
#!/bin/sh
#SBATCH --partition=bigmem
#SBATCH --qos=bigmem
#SBATCH --time=3-23:59:59
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=64G
#SBATCH --mail-type=ALL
#SBATCH --workdir=/tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/phasm-benchmarks

rm -rf /tmp/lrvandijk/assemblies/{assembly}
mkdir -p /tmp/lrvandijk/assemblies/{assembly}
cp -r * /tmp/lrvandijk/assemblies/{assembly}
cd /tmp/lrvandijk/assemblies/{assembly}
rm -rf .snakemake/
touch genomes/*/genome.fasta

sleep 1

snakemake --keep-going --cores=2 -f \\
    reads/error_free/{reads}.fasta

sleep 2

snakemake --keep-going --cores=2 -f \\
    assemblies/{assembly}/04_phase/{assembly}.fasta

mkdir -p /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/assemblies/{assembly}/00_reads
cp -r assemblies/{assembly}/* /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/assemblies/{assembly}
cp reads/error_free/* \\
    /tudelft.net/staff-bulk/ewi/insy/DBL/lrvandijk/assemblies/{assembly}/00_reads
"""

for assembly in config['assemblies'].keys():
    fname = "phasm_{}.sh".format(assembly)
    with open(fname, "w") as f:
        reads = assembly.replace("-error-free", "")
        f.write(TEMPLATE.format(assembly=assembly, reads=reads).lstrip())
