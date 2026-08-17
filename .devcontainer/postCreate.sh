#!/usr/bin/env bash
# Provision the environment to render the R Quarto website.
# Installs system libraries required by the R packages in renv.lock,
# then restores the renv project library (binary packages from PPM).
set -euo pipefail

echo "==> Installing system libraries for R packages"
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
  libuv1 \
  libcurl4-openssl-dev \
  libssl-dev \
  libxml2-dev \
  libfontconfig1-dev \
  libfreetype6-dev \
  libpng-dev \
  libtiff5-dev \
  libjpeg-dev \
  libharfbuzz-dev \
  libfribidi-dev \
  libgit2-dev \
  zlib1g-dev \
  libicu-dev \
  libcairo2-dev \
  libx11-dev \
  libxt-dev
sudo rm -rf /var/lib/apt/lists/*

echo "==> Restoring renv project library"
cd "$(git rev-parse --show-toplevel)"
Rscript -e 'options(renv.config.ppm.enabled = TRUE); renv::restore(prompt = FALSE)'

echo "==> Setup complete. Render with: quarto render"
