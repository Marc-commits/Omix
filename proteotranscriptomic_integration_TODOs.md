# TODOs from the proteotranscriptomic (asl3888as/pMBA51) integration project

Surfaced 2026-08-05 while integrating RNA-seq + LFQ proteomics for a
prokaryote (*Nostoc* sp. PCC 7120) via this fork's prokaryote-support
branch. Full context: `2026-08-05_Omix.md` in
`/mnt/u/Documents/data/omic_integration/3888as_pMBA51_0_26h/proteotranscriptomic`.

- [ ] Fix `rna_DE_analysis()`'s `format_res_deseq()` call
      (`R/DE_formating.R:110-111`), which unconditionally matches
      `gene_id_conversion` against a column literally named
      `ensembl_gene_id` — that column only exists when
      `generate_multiassay()` classified the RNA rownames as Ensembl IDs
      (`R/generate_multiassay.R:165`); for gene-symbol/locus-tag rownames
      only `gene_name`/`gene_biotype` exist, so the join silently returns
      all-`NA` gene names, which then crashes the internal
      `pathway_analysis_enrichr()` call once any contrast has significant
      genes. `protein_DE_analysis()` already guards this correctly
      (`is.null(gene_id_conversion$uniprot_id)` check,
      `R/protein_DE_analysis.R:195-197`) — mirror that guard in
      `rna_DE_analysis()`/`format_res_deseq()`. Confirmed by actually
      running the pipeline, not just reading source; will affect any
      RNA-seq dataset whose rownames aren't Ensembl gene IDs, not just
      prokaryotes.
- [ ] Fix `integrate_with_MOFA()`'s (`R/integrative_models.R:263-303`)
      metadata pass-through — it calls `MOFA2::create_mofa(X)` with no
      explicit `groups=`, so MOFA2 auto-assigns every sample to a single
      internal group literally named `"group1"`, then does
      `MOFA2::samples_metadata(MOFAobject) <- metadata` with the full,
      unmodified sample metadata from `vertical_integration()`. If that
      metadata has a column literally named `group` (a natural choice, and
      exactly what `vertical_integration()`'s own `dependent = "Group"`
      default nudges users toward, `R/vertical_integration.R:46`),
      MOFA2's `samples_metadata<-` setter validates it against
      `groups(MOFAobject)` and crashes with "Groups names in the model
      ... and in the metadata do not match" — only after MOFA training
      itself completes and converges, so it's easy to miss in a partial
      run. Fix by dropping/renaming any `group` column from the metadata
      passed to `MOFA2::samples_metadata<-`, or by passing real
      `groups=` through to `create_mofa()` instead of relying on the
      single-group default. Confirmed by actually running the pipeline,
      not just reading source; not organism/ID-format specific — will hit
      any dataset whose metadata has a `group` column. Worked around
      downstream by renaming our metadata's biological factor column from
      `group` to `condition`.
- [ ] Fix `get_ID_type()`'s (`R/get.R:145-176`) single-element regex
      heuristic — it only tests the *first* element of a gene/protein ID
      vector against an all-uppercase regex, so mixed-case/locus-tag-style
      symbols (e.g. `hemA`, `asl0046`) get misclassified as
      `"not_identified"`. That makes `get_multimodal_object()`
      (`R/get.R:240-278`) wrongly assume a UniProt-ID conversion is
      needed; the conversion returns `NULL`, and `vertical_integration()`
      crashes with `Error in make.unique(names) : 'names' must be a
      character vector`. Confirmed by actually running the pipeline, not
      just reading source; worked around downstream by passing
      `ID_type = "original"` to `vertical_integration()`, but will hit any
      dataset whose gene/protein symbols aren't in Omix's expected
      human/mouse/Ensembl/UniProt-style formats, not just prokaryotes.
      This is the concrete crash the existing regex-casing item below was
      only speculating about.
- [ ] Fix `process_rna()`'s unguarded `covariates=NULL` formula paste
      (`R/process_rna.R:73`) — crashes with "unexpected end of input";
      `process_protein()` already guards this correctly, mirror that
      fix. No existing test exercises `covariates=NULL`.
- [ ] Guard `annotation_lookup()`'s `GENETYPE`/`UNIPROT` column requests
      (`R/generate_multiassay.R:326-337`, `216`): check
      `"GENETYPE" %in% AnnotationDbi::columns(db)` (or the equivalent
      keytype validity check for `UNIPROT`) before querying, falling
      back to NA/none instead of erroring, for OrgDb objects that
      weren't built with that table (e.g. a minimal AnnotationForge-built
      prokaryote OrgDb).
- [ ] Add an organism gate / opt-out to
      `integrative_results_supervised()`/`_unsupervised()`/
      `_sparse_supervised()` so `ctd`/`disease_id` can be `NULL` and the
      internal `cell_type_enrichment()`/`OpenTarget_dataframe()` calls
      are skipped; gate `multi_omic_report()` the same way.
- [ ] Fix the false claim in
      `vignettes/Omix_vignette_prokaryote.Rmd:293-315` that
      EWCE/OpenTargets/etc. are "opt-in functions you simply don't call"
      — the actual `integrative_results_*()` entry points call them
      internally and unconditionally.
- [ ] Default `pathway_analysis_enrichr()` (`R/enrichment.R:29-40`) and
      `integrated_enrichment_mutliGSEA()`
      (`R/integrated_enrichment_multiGSEA.R:18-22`) away from silently
      querying human/mouse-only libraries/databases when no organism is
      specified — error or warn loudly instead of returning
      near-empty/mismatched results.
- [ ] Prune unused `clusterProfiler::enrichGO`/`compareCluster` and
      `org.Hs.eg.db` imports (`R/integrative_results_supervised.R`,
      `_unsupervised.R`, `_clustering.R`) — dead code, unnecessary hard
      dependencies.
- [ ] Add integration-level test coverage: run a synthetic
      non-human/non-mouse dataset through the FULL pipeline
      (`generate_multiassay` -> `process_rna`/`process_protein` -> DE ->
      `vertical_integration` -> `integrative_results_*`) using a minimal
      AnnotationForge-style OrgDb that lacks `GENETYPE`, to catch bugs
      like the above (existing tests only unit-test the
      annotation-resolution layer in isolation).
- [ ] Consider adding a CI trigger for `feature/prokaryote-support`
      directly (currently `.github/workflows/` only run on push/PR to
      `main`/`master` or other named dev branches).
- [ ] Review `get_ID_type()`'s regex heuristic for non-human gene ID
      casing conventions (flagged by a test comment in
      `tests/testthat/test-generate_multiassay.R:24-27`).
