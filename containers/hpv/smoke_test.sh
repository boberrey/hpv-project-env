#!/bin/bash
# Smoke test of the image: every tool runs, Python packages import, R writes a PDF in Arial,
# and bowtie2/samtools/pysam work together on a tiny genome. Run at build time; can be re-run with
#   apptainer exec <sif> bash /opt/hpv-project-env/smoke_test.sh
set -euo pipefail
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cd "$tmp"

for tool in bowtie2 bowtie2-build minimap2 samtools bgzip tabix pigz mash blastn dustmasker makeblastdb fasterq-dump; do
    command -v "$tool" > /dev/null || { echo "missing: $tool" >&2; exit 1; }
done
python -c "import numpy, pandas, scipy, pysam, Bio; print('python', __import__('sys').version.split()[0], 'pysam', pysam.__version__)"

# A random 5 kb genome, reads drawn from it, aligned and read back with pysam
python - <<'EOF'
import random
random.seed(1)
g = "".join(random.choice("ACGT") for _ in range(5000))
open("g.fa", "w").write(">g\n" + g + "\n")
with open("r.fq", "w") as f:
    for i in range(100):
        s = random.randrange(0, 4950)
        f.write(f"@r{i}\n{g[s:s+50]}\n+\n{'I'*50}\n")
EOF
bowtie2-build -q g.fa g
bowtie2 --no-unal -x g -U r.fq 2> /dev/null | samtools sort -o r.bam -
samtools index r.bam
python -c "import pysam; n = pysam.AlignmentFile('r.bam').mapped; assert n == 100, n"
minimap2 -a g.fa r.fq 2> /dev/null | samtools view -c -F 4 - | grep -qx 100
mash sketch -o g g.fa > /dev/null 2>&1
dustmasker -in g.fa -outfmt acclist > /dev/null

# R: plotting packages and an Arial PDF
Rscript -e 'suppressPackageStartupMessages({library(ggplot2); library(patchwork); library(ggrastr); library(data.table)});
  p <- ggplot(data.frame(x = 1:3, y = 1:3), aes(x, y)) + geom_point() + theme_classic(base_family = "Arial");
  ggsave("t.pdf", p, width = 2, height = 2, device = grDevices::cairo_pdf); stopifnot(file.size("t.pdf") > 0)'
echo "smoke test OK"
