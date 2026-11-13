#!/usr/bin/env bash
# Run Bactopia (AMR genes, MLST, species/serotype typing) on NCBI assemblies.
#   ./main.sh --test --env laptop
#   ./main.sh --input data/npgg_125_accessions.txt --env seqera --outdir results
#   ./main.sh --samples my_samples.tsv --env ccloud --outdir s3://BUCKET/results
set -euo pipefail

INPUT=""; SAMPLES=""; ENVNAME="laptop"; OUTDIR="results"
ORGANISM="Escherichia"; SPECIES="Escherichia coli"; FASTA_DIR="data/fasta"
PROFILE="docker"; EXTRA=()

usage() {
  cat <<'U'
Usage: ./main.sh (--test | --input ACCESSIONS.txt | --samples TABLE.tsv) [options]
  --test            run the 5 test genomes (data/test), output to test-run/
  --input FILE      list of NCBI assembly accessions, one per line (downloaded, then run)
  --samples FILE    ready sample table from 'bactopia prepare' (skips download)
  --env NAME        laptop (default) | codespaces | seqera | ccloud
  --organism NAME   AMRFinder+ organism group (default: Escherichia)
  --species NAME    species for 'bactopia prepare' (default: "Escherichia coli")
  --fasta-dir DIR   where assemblies are stored (default: data/fasta)
  --outdir DIR      output folder (default: results)
  --profile NAME    Nextflow container profile (default: docker)
Any other option is passed to bactopia unchanged.
U
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --test)      INPUT="data/test/test_accessions.txt"; FASTA_DIR="data/test/fasta"; OUTDIR="test-run"; shift ;;
    --input)     INPUT="$2"; shift 2 ;;
    --samples)   SAMPLES="$2"; shift 2 ;;
    --env)       ENVNAME="$2"; shift 2 ;;
    --organism)  ORGANISM="$2"; shift 2 ;;
    --species)   SPECIES="$2"; shift 2 ;;
    --fasta-dir) FASTA_DIR="$2"; shift 2 ;;
    --outdir)    OUTDIR="$2"; shift 2 ;;
    --profile)   PROFILE="$2"; shift 2 ;;
    -h|--help)   usage; exit 0 ;;
    *)           EXTRA+=("$1"); shift ;;
  esac
done

# Resource limits per environment (laptop values were tested; the others are first guesses)
CONF=""
case "$ENVNAME" in
  laptop)     CPUS=2; MEM="5.GB" ;;
  codespaces) CPUS=2; MEM="6.GB" ;;
  seqera)     CPUS=4; MEM="16.GB"; CONF="conf/seqera.config" ;;
  ccloud)     CPUS=4; MEM="16.GB"; CONF="conf/ccloud.config" ;;
  *) echo "Unknown --env: $ENVNAME"; usage; exit 1 ;;
esac

if [[ -z "$SAMPLES" ]]; then
  [[ -z "$INPUT" ]] && { usage; exit 1; }
  if command -v datasets >/dev/null 2>&1; then
    bash scripts/download_assemblies.sh "$INPUT" "$FASTA_DIR"
  else
    conda run -n ncbi --no-capture-output bash scripts/download_assemblies.sh "$INPUT" "$FASTA_DIR"
  fi
  SAMPLES="${OUTDIR%/}.samples.tsv"
  bactopia prepare --path "$FASTA_DIR" --species "$SPECIES" > "$SAMPLES"
fi

ARGS=(--samples "$SAMPLES" --outdir "$OUTDIR" --ask_merlin --ectyper_verify
      --amrfinderplus_organism "$ORGANISM" --max_cpus "$CPUS" --max_memory "$MEM"
      -profile "$PROFILE")
[[ -n "$CONF" ]] && ARGS+=(--nfconfig "$CONF")

exec bactopia "${ARGS[@]}" ${EXTRA[@]+"${EXTRA[@]}"}
