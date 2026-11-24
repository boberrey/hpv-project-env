# Pinned image of the HPV project. Changing anything here changes the environment version:
# record it in CHANGELOG.md. Analysis repos copy HPV_IMAGE, HPV_SIF and HPV_LOCK_MD5 into their own
# config.sh (see README.md).

# Where the .sif files live on this HPC (filled by containers/pull_image.sbatch).
# On another HPC, change this line only.
CONTAINER_DIR="$GROUP_HOME/containers/hpv-project"

# Built from containers/hpv by GitHub Actions (image version 0.1.0)
HPV_IMAGE="ghcr.io/boberrey/hpv-project-env@sha256:PENDING_FIRST_BUILD"
HPV_SIF="$CONTAINER_DIR/hpv-project-env_0.1.0.sif"
# md5 of the image's r_packages.lock.tsv followed by conda.lock (printed by pull_image.sbatch)
HPV_LOCK_MD5="PENDING_FIRST_BUILD"
