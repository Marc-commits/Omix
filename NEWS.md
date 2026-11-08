# Omix News

## Omix 1.1.3

* `EnsDb.Hsapiens.v86`, `org.Hs.eg.db`, `org.Mm.eg.db` and `msigdbr` moved
  from `Imports` to `Suggests`. They were only used for `organism = "human"`
  or `"mouse"` (`msigdbr` only in commented-out code), yet made every
  installation of Omix, including ones for bacteria, pull in the human and
  mouse annotation databases. `generate_multiassay()` now stops with an
  install hint if the package for the chosen human/mouse organism is missing;
  `get_module_annotation()` skips with a warning. Anyone using
  `organism = "human"` or `"mouse"` must install the package: the Docker image
  built from `docker/Dockerfile` no longer includes them
  (`remotes::install_local()` does not install `Suggests`).
* New option `omix.use_basilisk` (default `TRUE`) for `integrate_with_MOFA()`
  and `integrate_with_MEFISTO()`. `options(omix.use_basilisk = FALSE)` makes
  MOFA2 use the Python found by reticulate (e.g. `RETICULATE_PYTHON`, with
  `mofapy2` installed) instead of building a basilisk conda environment.
  Default behaviour is unchanged.

## Omix 1.1.2

* Moved Docker-related files into a `docker/` directory: `Dockerfile` is now
  `docker/Dockerfile`, and the leftover `Dockerfile.pinned`,
  `Dockerfile.pinned_and_linted`, `HADOLINT_FIXES.md`, `CHANGES.md` scratch
  files from an earlier apt-pinning pass moved there too. `.dockerignore`
  stays at the repo root (the build context) and now excludes `/docker`
  entirely, since none of its contents need to end up inside the built
  image or R source tarball.
* Updated all four GitHub Actions workflows' `file:` path to
  `./docker/Dockerfile`, and `scripts/docker-ci-check.sh`'s `-f` flags to
  match.
* Added `docker/build.sh`: a minimal script that just builds the image
  (`docker/build.sh [tag]`, defaults to `omix:latest`). For the full CI
  emulation (Dockerfile lint check + build), use
  `scripts/docker-ci-check.sh` as before.

## Omix 1.1.1

* Removed the `synapser` package as a hard build/CI dependency. It's no
  longer installed in the Docker image, and the `SYNAPSE_ID`/
  `SYNAPSE_PASSWORD` build secrets are no longer passed to the Docker
  build in any GitHub Actions workflow -- CI no longer needs Synapse
  credentials to pass.
* `Omix_vignette_CV_MTG.Rmd` and `Omix_vignette_MAP_CV_pseudotemporal.Rmd`
  (which pull their example data from the private, in-house Multi-Omics
  Atlas Project on Synapse) now detect a missing `synapser` package via
  `requireNamespace()` and stop with `knitr::knit_exit()`, rendering only
  descriptive text instead of erroring during vignette build.
* Re-pinned the Dockerfile's apt package versions, several of which had
  aged out of the Ubuntu 22.04 mirror since they were first pinned.
* Added `.dockerignore` so stray non-package files at the repo root (e.g.
  export artifacts with non-portable filenames) can't get copied into the
  Docker build context and fail `R CMD check`'s portable-filename check.
* Added `scripts/docker-ci-check.sh` to emulate the GitHub Actions CI
  locally: `docker build --check` followed by a full `docker buildx
  build` (this repo's CI is entirely the Docker build; its final layer
  runs `devtools::check(error_on = 'error')`).

## Omix 1.1.0

* `generate_multiassay()`'s `organism` argument now resolves any installed
  Bioconductor annotation package following the `org.*.eg.db` naming
  convention (e.g. `"org.EcK12.eg.db"` for *E. coli* K-12), in addition to
  the existing `"human"`/`"mouse"` values -- including packages built for
  organisms with no existing package via
  `AnnotationForge::makeOrgPackage()`.
* Added a new `annotation` argument to `generate_multiassay()`: a
  data.frame fallback annotation source (`gene_name`/`gene_biotype`,
  keyed by raw RNA/protein ID) for organisms with no installed annotation
  package -- e.g. a Prokka/Bakta/eggNOG-mapper export for a bacterial
  genome. If neither an annotation package nor a table resolves, the
  pipeline now warns and continues (raw IDs as gene names, no biotype)
  instead of erroring.
* Fixed a bug in the `organism = "mouse"` path of `generate_multiassay()`:
  it previously requested EnsDb-only columns/keytypes
  (`GENEBIOTYPE`/`UNIPROTID`) against `org.Mm.eg.db`, an OrgDb, which
  doesn't have them. It now uses the correct OrgDb columns/keytypes
  (`GENETYPE`/`UNIPROT`), with `GENETYPE` normalised to match the
  `GENEBIOTYPE` convention used elsewhere in the pipeline.
* Fixed a bug in `process_rna()`: with `protein_coding = TRUE` but no
  resolved `gene_biotype` annotation, the filter used to silently drop
  every gene rather than erroring or skipping. It now skips the filter
  with a warning.
* `get_module_annotation()` gained an `organism` argument; for any
  organism other than `"human"`/`"mouse"` (the only two
  `WGCNA::GOenrichmentAnalysis()` natively supports here) it now warns
  and returns `NULL` instead of erroring.
* Added a new vignette, `Omix_vignette_prokaryote.Rmd`, walking through
  both non-eukaryote annotation paths on a synthetic bacterial dataset,
  and documenting which downstream features remain eukaryote/mammalian-
  specific (EWCE, OpenTargets, multiGSEA, pseudotime, WGCNA module GO
  annotation).
* Added the package's first automated tests (`tests/testthat/`), covering
  the annotation-resolution logic above.

## Omix 1.0.0

* Added a `NEWS.md` file to track changes to the package.
