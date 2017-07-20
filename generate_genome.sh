SCRIPT_DIR=$(dirname "$0")
BASE_GENOME="${SCRIPT_DIR}/base/s.cerevisiae.fasta"

if (( $# < 2 ))
then
    echo "Usage: ${0} chromosome_spec output_dir"
    exit;
fi

SPEC_FILE="${1}"
OUTPUT_DIR="${2}"

mkdir -p ${OUTPUT_DIR}/haplotypes

aneusim haplogen -r -s ${SPEC_FILE} ${BASE_GENOME} ${OUTPUT_DIR}/haplotypes
cat ${OUTPUT_DIR}/haplotypes/*.fasta > "${OUTPUT_DIR}/genome.fasta"
