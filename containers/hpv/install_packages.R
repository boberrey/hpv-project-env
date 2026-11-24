# Install the image's R packages, check they load, and write the package lockfile.
# CRAN and Bioconductor versions come from the dated snapshots set in the Dockerfile.

snapshot <- Sys.getenv("CRAN_SNAPSHOT")
bioc_snapshot <- Sys.getenv("BIOC_SNAPSHOT")
bioc_version <- Sys.getenv("BIOC_VERSION")
stopifnot(nzchar(snapshot), nzchar(bioc_snapshot), nzchar(bioc_version))
options(repos = c(CRAN = snapshot), Ncpus = parallel::detectCores(),
        BioC_mirror = bioc_snapshot, BIOCONDUCTOR_CONFIG_FILE = paste0(bioc_snapshot, "/config.yaml"))

# Plotting (R/plotting.R from rna-flex-preprocess needs ggplot2, ggrastr, patchwork, scales) and tables
cran_pkgs <- c("ggplot2", "ggrastr", "patchwork", "scales", "data.table", "R.utils", "optparse",
               "BiocManager")
install.packages(cran_pkgs)
# Bioconductor: none yet (add with BiocManager::install(..., version = bioc_version, update = FALSE))
bioc_pkgs <- character(0)

# install.packages() only warns when a package fails, so load every one
for (p in c(cran_pkgs, bioc_pkgs)) library(p, character.only = TRUE)
stopifnot(capabilities("cairo"), BiocManager::version() == bioc_version)

# Lockfile: every non-base package, its version and where it came from
ip <- as.data.frame(installed.packages(fields = "biocViews"), stringsAsFactors = FALSE)
ip <- ip[!duplicated(ip$Package) & (is.na(ip$Priority) | ip$Priority != "base"), ]
src <- ifelse(ip$LibPath == .Library, paste0("R ", getRversion()),
       ifelse(!is.na(ip$biocViews) & nzchar(ip$biocViews), paste0(bioc_snapshot, " (Bioconductor ", bioc_version, ")"),
              snapshot))
lock <- data.frame(package = ip$Package, version = ip$Version, source = src)
write.table(lock[order(tolower(lock$package)), ], "/opt/hpv-project-env/r_packages.lock.tsv",
            sep = "\t", quote = FALSE, row.names = FALSE)
