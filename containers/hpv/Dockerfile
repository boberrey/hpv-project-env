# Software environment for the HPV project: R (plotting, later single-cell analysis), Python and
# command-line genomics tools. Later analyses either add packages here (bump VERSION) or build on it:
#   FROM ghcr.io/boberrey/hpv-project-env:<version>
# Built and pushed by .github/workflows/build-image.yml. Bump VERSION for every change.
FROM rocker/r-ver:4.6.2@sha256:4383092318935c298533466f753354a7dfdc75a6e12edfb93a0f13c8a97135f9

# R: one dated snapshot (Posit Package Manager binaries for this Ubuntu release) fixes every CRAN and
# Bioconductor package version. Python and command-line tools: a micromamba environment with exact
# versions (environment.yml); the solved package list (with builds) is written to conda.lock.
ENV CRAN_SNAPSHOT=https://p3m.dev/cran/__linux__/resolute/2026-11-06 \
    BIOC_SNAPSHOT=https://p3m.dev/bioconductor/__linux__/resolute/2026-11-06 \
    BIOC_VERSION=3.23 \
    MICROMAMBA_VERSION=2.10.0 \
    MICROMAMBA_SHA256=9a97976244929bbae28fb1fae504e74a3e7e6d1932870e3a03321f01b7fbd07b \
    MAMBA_ROOT_PREFIX=/opt/micromamba \
    CONDA_ENV=/opt/conda-env

# System libraries for the R packages (Cairo, fonts, images, compression) and Liberation fonts,
# which fontconfig substitutes for Arial/Helvetica
RUN apt-get update && apt-get install -y --no-install-recommends \
        pkg-config libcairo2-dev libxt-dev libfontconfig1-dev libfreetype-dev \
        libharfbuzz-dev libfribidi-dev libpng-dev libjpeg-dev libtiff-dev \
        libxml2-dev libcurl4-openssl-dev libssl-dev zlib1g-dev libbz2-dev liblzma-dev \
        fontconfig fonts-liberation bzip2 ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && fc-match Arial | grep -q Liberation

# Python and command-line tools
COPY environment.yml /opt/hpv-project-env/
RUN curl -fsSL "https://micro.mamba.pm/api/micromamba/linux-64/${MICROMAMBA_VERSION}" -o /tmp/micromamba.tar.bz2 \
    && echo "${MICROMAMBA_SHA256}  /tmp/micromamba.tar.bz2" | sha256sum -c - \
    && tar -xjf /tmp/micromamba.tar.bz2 -C /usr/local bin/micromamba \
    && rm /tmp/micromamba.tar.bz2 \
    && micromamba create -y -p "${CONDA_ENV}" -f /opt/hpv-project-env/environment.yml --channel-priority strict \
    && micromamba env export -p "${CONDA_ENV}" --explicit --md5 | grep -v '^#' > /opt/hpv-project-env/conda.lock \
    && micromamba clean -a -y
# The environment comes first in PATH; it has no R, so R stays rocker's
ENV PATH="${CONDA_ENV}/bin:${PATH}" \
    PYTHONNOUSERSITE=1 \
    PYTHONDONTWRITEBYTECODE=1

# R packages and the R package lockfile
COPY install_packages.R VERSION /opt/hpv-project-env/
RUN Rscript /opt/hpv-project-env/install_packages.R \
    && echo "options(repos = c(CRAN = '${CRAN_SNAPSHOT}'), BioC_mirror = '${BIOC_SNAPSHOT}', \
BIOCONDUCTOR_CONFIG_FILE = '${BIOC_SNAPSHOT}/config.yaml')" >> "${R_HOME}/etc/Rprofile.site"

# Every tool and package works
COPY smoke_test.sh /opt/hpv-project-env/
RUN bash /opt/hpv-project-env/smoke_test.sh
