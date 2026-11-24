# HPV project — software environment

One Apptainer image for the analyses of the HPV multiome project: R, Python and command-line genomics
tools at pinned versions. It is built the same way as the rna-flex-preprocess images (GitHub Actions →
GitHub Container Registry, pulled by digest, package lists checked before use), but is a separate image.

**Version 0.1.0** (lean): what HPV typing (`determine_HPV_type`) needs.

| Layer | Contents |
| --- | --- |
| Base | `rocker/r-ver:4.6.2` (Ubuntu), pinned by digest; Liberation fonts (substituted for Arial) |
| R | ggplot2, ggrastr, patchwork, scales, data.table, R.utils, optparse (CRAN snapshot 2026-11-06, Bioconductor 3.23) |
| Python 3.12 | numpy, pandas, scipy, pysam, biopython |
| Tools | bowtie2, minimap2, samtools, htslib (bgzip, tabix), pigz, mash, BLAST+ (blastn, dustmasker), sra-tools |

Exact versions: `containers/hpv/environment.yml` (Python and tools; builds in `containers/hpv/conda.lock`)
and `containers/hpv/r_packages.lock.tsv` (R).

## Layout
- `containers/hpv/`: `Dockerfile`, `environment.yml`, `install_packages.R`, `smoke_test.sh`, `VERSION`, and the
  package lockfiles written from the built image.
- `config.sh`: the pinned image digest, where the `.sif` lives, and the md5 of the lockfiles.
- `env.sh`: `hpv_exec` (run a command in the image) and `check_hpv_image` (the image matches the lockfiles).
- `containers/pull_image.sbatch`: pulls the pinned image and checks it.
- `.github/workflows/build-image.yml`: builds and pushes the image when `containers/hpv/` changes on main.

## Setup (once per HPC)
1. Clone the repo; in `config.sh`, set `CONTAINER_DIR` (where the `.sif` files go).
2. `sbatch containers/pull_image.sbatch` (from the repo root). It pulls the image by digest, compares its
   package lists with the committed lockfiles, prints `HPV_LOCK_MD5` and runs the smoke test.

## Using the image in an analysis repo
Copy `HPV_IMAGE`, `HPV_SIF` and `HPV_LOCK_MD5` into the analysis repo's `config.sh`, and the two functions of
`env.sh` into its shared shell file. Run every step through `hpv_exec`, after `check_hpv_image`:
```bash
source config.sh; source env.sh
check_hpv_image
hpv_exec python my_script.py
hpv_exec Rscript my_plots.R
```
`--cleanenv` keeps host settings (`R_LIBS`, `PYTHONPATH`, loaded modules) out of the image.

## Extending the image
1. Add the package:
   - Python or command-line tool: `containers/hpv/environment.yml`, with an exact version
     (conda-forge or bioconda).
   - R from CRAN: `cran_pkgs` in `containers/hpv/install_packages.R` (the version comes from the dated
     snapshot in the `Dockerfile`; move `CRAN_SNAPSHOT`/`BIOC_SNAPSHOT` together for newer versions).
   - R from Bioconductor: `bioc_pkgs` (install line in the comment there).
   - Add a check to `smoke_test.sh` when the package has a command or a non-trivial setup.
2. Bump `containers/hpv/VERSION` (minor for additions, major for version changes of existing packages) and
   push to main. GitHub Actions builds and pushes the image; the run summary shows the digest.
3. Put the digest and the new `.sif` name in `config.sh`, delete the two lockfiles, and run
   `sbatch containers/pull_image.sbatch`. It writes the new lockfiles and prints the new `HPV_LOCK_MD5`.
4. Set `HPV_LOCK_MD5` in `config.sh`; commit `config.sh`, the lockfiles and a CHANGELOG entry.
5. Analysis repos move to the new version by updating their three pinned values; old `.sif` files stay
   in `CONTAINER_DIR`, so finished analyses keep running on their version.

A later, larger environment (for example the single-cell stack) can also be its own image built on this one:
`FROM ghcr.io/boberrey/hpv-project-env:<version>`.
