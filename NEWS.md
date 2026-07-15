# Omix News

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
