#!/usr/bin/env bash
# One-time setup for Codespaces / a fresh Linux machine: Miniforge, Bactopia, NCBI datasets.
set -euo pipefail
INSTALLER="Miniforge3-$(uname)-$(uname -m).sh"
curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/${INSTALLER}"
bash "${INSTALLER}" -b -p "$HOME/miniforge3"
rm "${INSTALLER}"
"$HOME/miniforge3/bin/conda" create -y -n bactopia -c conda-forge -c bioconda bactopia
"$HOME/miniforge3/bin/conda" create -y -n ncbi -c conda-forge ncbi-datasets-cli unzip
echo 'source ~/miniforge3/etc/profile.d/conda.sh && conda activate bactopia' >> ~/.bashrc
