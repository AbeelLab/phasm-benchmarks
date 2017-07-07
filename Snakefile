import os
import glob

configfile: "config.yml"

GENOMES_DIR = "genomes"
ASSEMBLIES_DIR = "assemblies"
READS_DIR = "reads"
ERROR_FREE_READS_DIR = os.path.join(READS_DIR, "error_free")
PACBIO_READS_DIR = os.path.join(READS_DIR, "pacbio")

# Phasm directories and files
BASE_DIR = os.path.join(ASSEMBLIES_DIR, "{assembly}")
OVERLAP_DIR = os.path.join(BASE_DIR, "01_overlap")
LAYOUT_DIR = os.path.join(BASE_DIR, "02_layout")
CHAIN_DIR = os.path.join(BASE_DIR, "03_chain")
PHASE_DIR = os.path.join(BASE_DIR, "04_phase")
ANALYSIS_DIR = os.path.join(BASE_DIR, "05_analysis")

DB_FILE = os.path.join(OVERLAP_DIR, "database.db")
DALIGNER_HPC_SH = os.path.join(OVERLAP_DIR, "daligner.sh")
LAS_FILE = os.path.join(OVERLAP_DIR, "alignments.las")
GFA_FILE = os.path.join(OVERLAP_DIR, "alignments.gfa")

ASSEMBLY_GRAPH_GFA = os.path.join(LAYOUT_DIR, "assembly_graph.gfa")
ASSEMBLY_GRAPH_GRAPHML = os.path.join(LAYOUT_DIR, "assembly_graph.graphml")

COMPONENT_FILE = os.path.join(CHAIN_DIR, "component{component_id}.gfa")
BUBBLECHAIN_FILE = os.path.join(CHAIN_DIR, "component{component_id}.bubblechain{bubblechain_id}.gfa")

PHASED_FASTA_FILE = os.path.join(PHASE_DIR, "component{component_id}.bubblechain{bubblechain_id}.fasta")
PHASED_CONCATENATED_FILE = os.path.join(PHASE_DIR, "{assembly}.fasta")

ALIGNED_CONTIGS_BAM = os.path.join(ANALYSIS_DIR, "aligned_contigs.bam")

DALIGNER_DEFAULTS = config.get('daligner', {
    'e': 0.99999999,
    'k': 20,
    'w': 1,
    'h': 45,
    'l': 1000,
    's': 100
})

PHASM_LAYOUT_OPTIONS = {'l', 's', 'a', 'r', 't', 'F'}
PHASM_LAYOUT_DEFAULTS = config.get('phasm', {}).get('layout', {
    'l': 5000
})

PHASM_PHASE_OPTIONS = {'t', 'd', 's'}
PHASM_PHASE_DEFAULTS = config.get('phasm', {}).get('phase', {
    't': 0.000001,
    'd': 0.1,
    's': 5
})

def get_daligner_option(assembly, option):
    if 'daligner' in config['assemblies'][assembly]:
        return config['assemblies'][assembly]['daligner'].get(option,
            DALIGNER_DEFAULTS[option])
    else:
        return DALIGNER_DEFAULTS[option]


def gen_option_str(opts, allowed):
    return " ".join("-{}{}".format(k, v) for k, v in opts.items() 
                    if v and k in allowed)


def get_phasm_layout_opts(assembly):
    opts = config['assemblies'][assembly].get('phasm', {}).get(
        'layout', PHASM_LAYOUT_DEFAULTS)

    return gen_option_str(opts, PHASM_LAYOUT_OPTIONS)


def get_phasm_phase_opts(assembly):
    opts = config['assemblies'][assembly].get('phasm', {}).get(
        'phase', PHASM_PHASE_DEFAULTS)

    return gen_option_str(opts, PHASM_PHASE_OPTIONS)


# Generates all assemblies
rule all:
    input:
        expand(PHASED_CONCATENATED_FILE, assembly=config['assemblies'].keys())

# Rule to generate all genomes at once
rule all_genomes:
    input: 
        expand(os.path.join(GENOMES_DIR, "{genome}", "genome.fasta"),
               genome=[genome for genome in os.listdir(GENOMES_DIR)
                       if os.path.isdir(os.path.join(GENOMES_DIR, genome))]
        )

# Generate all readsets
rule all_errorfree_readsets:
    input:
        expand(os.path.join(ERROR_FREE_READS_DIR, "{readset}.fasta"),
               readset=config['readsets'].keys())

#
# Benchmark genomes generation
#

rule generate_genome:
    input:
        os.path.join(GENOMES_DIR, "{genome}", "chromosomes.spec")
    output:
        os.path.join(GENOMES_DIR, "{genome}", "genome.fasta")
    params:
        output_dir = lambda wildcards: os.path.join(GENOMES_DIR, wildcards['genome'])
    shell:
        "./generate_genome.sh {input} {params.output_dir}"

# Read generation

# Simulated PacBio-like reads
rule pacbio_sim:
    input:
        lambda wildcards: os.path.join(
            GENOMES_DIR, config['readsets'][wildcards.readset]['genome'], "genome.fasta")
    output:
        os.path.join(PACBIO_READS_DIR, "{readset}.fastq"),
        os.path.join(PACBIO_READS_DIR, "{readset}.fastq.sam"),
        os.path.join(PACBIO_READS_DIR, "{readset}.fastq.faidx")
    params:
        coverage = lambda wildcards: config['genomes'][wildcards.genome]['coverage']
    shell:
        """
        simlord --read-reference {input} --coverage {params.coverage} {output[0]}
        samtools faidx {output[0]}
        """

# Error free reads
rule error_free_data:
    input:
        lambda wildcards: os.path.join(
            GENOMES_DIR, config['readsets'][wildcards.readset]['genome'], "genome.fasta")
    output:
        os.path.join(ERROR_FREE_READS_DIR, "{readset}.fasta"),
        os.path.join(ERROR_FREE_READS_DIR, "{readset}.json")
    params:
        coverage = lambda wildcards: config['readsets'][wildcards.readset]['coverage']
    shell:
        """
        aneusim reads -c {params.coverage} -o {output[0]} -m {output[1]} {input}
        samtools faidx {output[0]}
        """

#
# PHASM Pipeline
# --------------
#
# The rules below describe the several steps in our PHASM
# pipeline.
#


rule createdb:
    input:
        lambda wildcards: config['assemblies'][wildcards.assembly]['reads']
    output:
        DB_FILE,
        os.path.join(OVERLAP_DIR, ".database.idx"),
        os.path.join(OVERLAP_DIR, ".database.bps"),
    log: os.path.join(OVERLAP_DIR, "createdb.log")
    shadow: "shallow"
    params:
        path = os.path.join(OVERLAP_DIR, "database.db"),
        # DAZZ_DB only accepts PacBio like FASTA headers, fix them
        # and store a translation JSON file.
        fasta_input = lambda wildcards, input: (
            "phasm-convert fasta2dazzdb -T{input}.json {input}"
            if config['assemblies'][wildcards.assembly].get('fix_headers', False)
            else "cat {input}"
        ).format(input=input),
        db_block_size = int(config['dazz_db']['blocksize'])
    shell:
        """
        {params.fasta_input} | fasta2DB {params.path} \
            -i{wildcards.assembly}.fasta > {log} 2>&1
        DBsplit -s{params.db_block_size} {params.path} >> {log} 2>&1
        DBdust {params.path} >> {log} 2>&1
        """

rule hpc_daligner:
    input:
        DB_FILE
    output:
        DALIGNER_HPC_SH
    log: os.path.join(OVERLAP_DIR, "daligner.log")
    params:
        mem = config['daligner']['mem'],
        k = lambda wildcards: get_daligner_option(wildcards.assembly, 'k'),
        w = lambda wildcards: get_daligner_option(wildcards.assembly, 'w'),
        h = lambda wildcards: get_daligner_option(wildcards.assembly, 'h'),
        e = lambda wildcards: get_daligner_option(wildcards.assembly, 'e'),
        l = lambda wildcards: get_daligner_option(wildcards.assembly, 'l'),
        s = lambda wildcards: get_daligner_option(wildcards.assembly, 's'),
    threads: int(config['daligner']['threads'])
    shell:
        "HPC.daligner -t{threads} -M{params.mem} -mdust -k{params.k} -w{params.w} -h{params.h} -e{params.e} "
        "-s{params.s} {input} 1> {output} 2>> {log}"


rule daligner:
    input:
        db = DB_FILE,
        cmd = DALIGNER_HPC_SH
    output:
        LAS_FILE
    log: os.path.join(OVERLAP_DIR, "daligner.log")
    threads: 4
    shadow: "shallow"
    params:
        db_name = os.path.join(OVERLAP_DIR, "database")
    run:
        shell("/usr/bin/env bash {input.cmd} >> {log} 2>&1")
        block_las_files = glob.glob(params.db_name + ".*.las")
        print(block_las_files)
        if len(block_las_files) == 0:
            shell('mv "{params.db_name}.las" {output}')
        else:
            shell('LAcat "{params.db_name}.#.las" > {output}')
            shell('rm -f "{params.db_name}.*.las"')

# Convert DALIGNER local alignments to GFA2
# Use earlier generated JSON translation file (see createdb)
# to use our original read ID's again.
rule phasm_gfa:
    input:
        db = DB_FILE,
        las = LAS_FILE
    output:
        GFA_FILE
    log: os.path.join(OVERLAP_DIR, "daligner.log")
    params:
        translation_file = lambda wildcards: config['assemblies'][wildcards.assembly]['reads'] + ".json"
    shell:
        "LAdump -ocd {input.db} {input.las} | phasm-convert daligner2gfa "
        "-T{params.translation_file} <(DBdump -rh {input.db}) 1> {output} 2>> {log}"

rule phasm_layout:
    input:
        GFA_FILE
    output:
        ASSEMBLY_GRAPH_GFA,
        ASSEMBLY_GRAPH_GRAPHML
    log: os.path.join(LAYOUT_DIR, "phasm-layout.log")
    params:
        opts = lambda wildcards: get_phasm_layout_opts(wildcards.assembly)
    shell:
        "phasm layout {params.opts} {input} -o {output[0]} -o {output[1]} 2> {log}"

rule phasm_chain:
    input:
        ASSEMBLY_GRAPH_GFA
    output:
        dynamic(BUBBLECHAIN_FILE)
    log: os.path.join(CHAIN_DIR, "phasm-chain.log")
    params:
        output_dir = CHAIN_DIR
    shell:
        "phasm chain -f gfa2,graphml -o {params.output_dir} {input} 2> {log}"

rule phasm_phase:
    input:
        reads = lambda wildcards: config['assemblies'][wildcards.assembly]['reads'],
        gfa = GFA_FILE,
        bubble_gfa = BUBBLECHAIN_FILE
    output:
        PHASED_FASTA_FILE
    log: os.path.join(PHASE_DIR, "phasm-phase.log")
    params:
        opts = lambda wildcards: get_phasm_phase_opts(wildcards.assembly),
        ploidy = lambda wildcards: config['assemblies'][wildcards.assembly]['ploidy']
    shell:
        "phasm phase -p {params.ploidy} {params.opts} {input[0]} {input{1]} {input[2]} "
        "> {output}  2> {log}"

rule phasm_concat:
    input:
        dynamic(PHASED_FASTA_FILE)
    output:
        PHASED_CONCATENATED_FILE
    shell:
        "cat {input} > {output}"

rule bwa_index:
    input:
        "{genome}.fasta"
    output:
        "{genome}.fasta.bwt",
        "{genome}.fasta.ann"
    shell:
        "bwa index {input}"


rule contig_align:
    input:
        PHASED_CONCATENATED_FILE,
        lambda wildcards: [config['assemblies'][wildcards.assembly]['reference']] + [
            config['assemblies'][wildcards.assembly]['reference'] + ext
            for ext in ('.bwt', '.ann')]
    output:
        ALIGNED_CONTIGS_BAM
    shell:
        """
        bwa mem {input[1]} {input[0]} | samtools view -uS - | samtools sort -o {output}
        samtools index {output}
        """
