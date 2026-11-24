# Shell helpers for running commands in the HPV project image. Source after config.sh:
#   source config.sh; source env.sh
# Analysis repos keep a copy of these two functions in their own shared shell file.

# Run a command inside the image. --cleanenv keeps host settings (R_LIBS, PYTHONPATH, ...) out.
# Temporary files go to the job's node-local scratch when there is one.
HPV_TMP="${L_SCRATCH_JOB:-${TMPDIR:-/tmp}}"
hpv_exec() { apptainer exec --cleanenv --bind "$HPV_TMP" --env TMPDIR="$HPV_TMP" "$HPV_SIF" "$@"; }

# The image must still match the pinned package lists
check_hpv_image() {
    [[ -f "$HPV_SIF" ]] || { echo "ERROR: missing $HPV_SIF; run containers/pull_image.sbatch in hpv-project-env" >&2; return 1; }
    local md5
    md5=$(hpv_exec cat /opt/hpv-project-env/r_packages.lock.tsv /opt/hpv-project-env/conda.lock | md5sum | cut -d' ' -f1)
    [[ "$md5" == "$HPV_LOCK_MD5" ]] || { echo "ERROR: $HPV_SIF packages (md5 $md5) differ from HPV_LOCK_MD5=$HPV_LOCK_MD5" >&2; return 1; }
}
