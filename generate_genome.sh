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

# Translocation of length 50000
cp "${SCRIPT_DIR}/base/haplotypes/BK006941.2.copy0.fasta" "${OUTPUT_DIR}/haplotypes/temp.fasta"
aneusim translocate -m 0 -l 50000 50000 --in-place \
    "${OUTPUT_DIR}/haplotypes/temp.fasta" ${OUTPUT_DIR}/haplotypes/*.copy0.fasta
rm "${OUTPUT_DIR}/haplotypes/temp.fasta"

cat ${OUTPUT_DIR}/haplotypes/*.fasta > "${OUTPUT_DIR}/genome.fasta"
