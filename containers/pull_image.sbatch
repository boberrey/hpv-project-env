#!/bin/bash
#SBATCH --job-name=hpv_pull_image
#SBATCH --partition=satpathy,normal
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#
# Pull the pinned image (config.sh) as a .sif file into $CONTAINER_DIR.
# Usage (from the repo root): sbatch containers/pull_image.sbatch
# An image that is already there is not pulled again. Then the image's package lists are checked
# against the committed copies in containers/hpv/ (written if missing: commit them).
set -euo pipefail

REPO=$(cd "${SLURM_SUBMIT_DIR:-.}" && git rev-parse --show-toplevel)
source "$REPO/config.sh"
source "$REPO/env.sh"

export APPTAINER_CACHEDIR="$SCRATCH/.apptainer_cache"
export APPTAINER_TMPDIR="${L_SCRATCH_JOB:-$SCRATCH}/apptainer_tmp"
mkdir -p "$CONTAINER_DIR" "$APPTAINER_TMPDIR"

if [[ -f "$HPV_SIF" ]]; then
    echo "already pulled: $HPV_SIF"
else
    apptainer pull "$HPV_SIF.tmp" "docker://$HPV_IMAGE"
    mv "$HPV_SIF.tmp" "$HPV_SIF"
fi

for f in r_packages.lock.tsv conda.lock; do
    committed="$REPO/containers/hpv/$f"
    if [[ -f "$committed" ]]; then
        hpv_exec cat "/opt/hpv-project-env/$f" | cmp -s - "$committed" || { echo "ERROR: image $f differs from $committed" >&2; exit 1; }
    else
        hpv_exec cat "/opt/hpv-project-env/$f" > "$committed"
        echo "wrote $committed: commit it"
    fi
done
md5=$(cat "$REPO/containers/hpv/r_packages.lock.tsv" "$REPO/containers/hpv/conda.lock" | md5sum | cut -d' ' -f1)
echo "HPV_LOCK_MD5=$md5"
[[ "$HPV_LOCK_MD5" == "$md5" ]] || echo "set HPV_LOCK_MD5=\"$md5\" in config.sh (and in analysis repos)"
hpv_exec bash /opt/hpv-project-env/smoke_test.sh
echo "Image OK: $HPV_SIF"
