# bactopia-amr-typing

A pre-configured [Bactopia](https://bactopia.github.io/) setup for finding AMR genes and typing bacterial genomes
(MLST, species and serotype checks). It wraps Bactopia and does not copy its code. Built for the
Nigerian Pathogen Genomics Group E. coli AMR study, and usable for other bacteria through the
`--organism` and `--species` options. Also meant as a Nextflow training repo.

## Quick start (5 test genomes)
    ./main.sh --test --env laptop

## What it runs
Bactopia 4.1.0 on NCBI assemblies: Prokka annotation, AMRFinderPlus (genes and point mutations),
MLST, and species-specific typing chosen by Merlin (`--ask_merlin`), with ECTyper species verification.
Bactopia simulates reads from each assembly (it does not re-assemble them).

## Environments (`--env`)
| env | status |
|---|---|
| laptop | tested: 2 CPUs, 5 GB RAM |
| codespaces | not tested; check disk size (images and work folder are large) |
| seqera | template only (conf/seqera.config), needs setting up |
| ccloud | Carolina Cloud lines from their docs, not tested with Bactopia |

## Inputs
- `data/test/test_accessions.txt`: 5 test genomes; the FASTA files are in `data/test/fasta/`.
- `data/npgg_125_accessions.txt`: the 125-isolate analysis set (accession versions included).
- Assemblies are downloaded with NCBI `datasets` and saved without the version; `accession_versions.txt` records the versions.
- Why not Bactopia's own accession input? Its accession check skipped GCA_060466715 ("from large multi-isolate project"), so we pass FASTA files.

## Tested so far (laptop, WSL2 Ubuntu)
Bactopia 4.1.0, Nextflow 26.10.5, Docker 29.7.2. 5 genomes took 6 h 26 min on 2 CPUs and 5 GB RAM,
and the work folder was 7.7 GB. The 125 genomes need the cloud.
The first run downloads about 40 Docker images (hours on a slow connection).

## Cloud notes (not tested)
`bactopia prepare` writes absolute paths. In the cloud, upload the FASTA files to the bucket and replace the path prefix:
    sed 's#/ABSOLUTE/PATH/data/fasta#s3://BUCKET/fasta#' results.samples.tsv > cloud.samples.tsv
Then run: `./main.sh --samples cloud.samples.tsv --env seqera --outdir s3://BUCKET/results`

## Cite
Petit III RA, Read TD. Bactopia: a flexible pipeline for complete analysis of bacterial genomes. mSystems 5 (2020).

## Results of the 5-genome test (laptop)
- AMRFinder+ organism `Escherichia` is accepted. Point mutations appear in `amrfinderplus.tsv` (Subtype `POINT`), not in a separate file.
- `--plus` also reports virulence and stress genes. Count resistance only from rows where `Type` is `AMR`.
- ECTyper species verification: all 5 isolates are *Escherichia coli*.
- Open question for the 125: one genome was typed with MLST scheme `escherichia_2` and the other four with `escherichia`.
  The two schemes' STs are not comparable. Check whether to force one scheme (see `bactopia --help_all | grep -i mlst`).
- Open question: most of the 6.5 hours may go to steps meant for raw reads (read simulation, QC, assembly).
  A leaner route for assemblies may exist.

## Run the 125 genomes
Force the standard E. coli MLST scheme for all isolates. On the 5 test genomes this typed all of them
under `escherichia` (without it, one genome was typed with `escherichia_2`, whose STs are not comparable).
This resolves the open MLST question above.

    ./main.sh --input data/npgg_125_accessions.txt --env <seqera|ccloud> --mlst_scheme escherichia
