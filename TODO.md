# TODO

Open items for the `feature/prokaryote-support` fork. Most were surfaced
2026-08-05 while integrating RNA-seq + LFQ proteomics for a prokaryote
(*Nostoc* sp. PCC 7120) in the
[CyanoOmix](https://github.com/Marc-commits/CyanoOmix) pipeline (its README,
"Known Omix/annotation-package limitations", numbers the bugs #1-#8; the
numbers are noted below). Re-verified 2026-11-14 against `381eada` (Omix
1.1.3): every bug below is still present and upstream
(`eleonore-schneeg/Omix`) has no fix. CyanoOmix works around each one
downstream, so none blocks it.

## Bugs (confirmed by running the pipeline, not just reading source)

- [ ] CyanoOmix #5: fix `rna_DE_analysis()`'s `format_res_deseq()` call
      (`R/DE_formating.R:110-113`), which unconditionally matches
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
      `rna_DE_analysis()`/`format_res_deseq()`. Affects any RNA-seq dataset
      whose rownames aren't Ensembl gene IDs, not just prokaryotes.
- [ ] CyanoOmix #8: fix `extract_weigths()`'s (`R/extract_weights.R:50-51`)
      feature-name recovery — it calls `sub("\\_.*", "", rownames(rna_1))`
      (and the equivalent for `protein_1`) to undo MOFA2's
      duplicate-across-view renaming (features present in both the `mRNA`
      and `proteins` views get suffixed `_mRNA`/`_proteins` by MOFA2's
      `.rename_duplicated_features()`), but the regex strips *everything*
      from the first underscore onward, not just a literal trailing
      suffix. This mangles any feature ID that legitimately contains an
      underscore — RefSeq locus tags (`PCC7120DELTA_RS00010`),
      paralog-numbered gene symbols (`cas6_2`), versioned Ensembl IDs
      (`ENSG00000141510.16` post-decimal-split) — and the mangled name then
      doesn't exist as a column in the data matrix passed to
      `multiomics_network()`, which crashes with `Error in matrix1[,
      list[[1]]] : subscript out of bounds`. Fix by anchoring the strip to
      a literal trailing suffix (`sub("_(mRNA|proteins)$", "", x)`), or by
      tracking the pre-MOFA/post-MOFA name mapping explicitly instead of
      reverse-engineering it via regex. Only triggers once the
      duplicate-feature renaming path is exercised (the same feature name
      in both views), so it is easy to miss without a full end-to-end test.
      CyanoOmix carries a local `extract_weigths_fixed()` with the
      corrected regex.
- [ ] CyanoOmix #7: fix `integrate_with_MOFA()`'s
      (`R/integrative_models.R:287,307`; `integrate_with_MEFISTO()` has the
      same pattern at 354/379) metadata pass-through — it calls
      `MOFA2::create_mofa(X)` with no explicit `groups=`, so MOFA2
      auto-assigns every sample to a single internal group literally named
      `"group1"`, then does `MOFA2::samples_metadata(MOFAobject) <-
      metadata` with the full, unmodified sample metadata from
      `vertical_integration()`. If that metadata has a column literally
      named `group` (a natural choice, and exactly what
      `vertical_integration()`'s own `dependent = "Group"` default nudges
      users toward, `R/vertical_integration.R:46`), MOFA2's setter
      validates it against `groups(MOFAobject)` and crashes with "Groups
      names in the model ... and in the metadata do not match" — only
      after MOFA training has completed. Fix by dropping/renaming any
      `group` column from the metadata passed to the setter, or by passing
      real `groups=` through to `create_mofa()`. Not organism-specific.
      CyanoOmix renames its factor from `group` to `condition`.
- [ ] CyanoOmix #6: fix `get_ID_type()`'s (`R/get.R:145-176`) single-element
      regex heuristic — it only tests the *first* element of a gene/protein
      ID vector against an all-uppercase regex, so mixed-case/locus-tag
      symbols (e.g. `hemA`, `asl0046`) get misclassified as
      `"not_identified"`. That makes `get_multimodal_object()`
      (`R/get.R:240-278`) wrongly assume a UniProt-ID conversion is
      needed; the conversion returns `NULL`, and `vertical_integration()`
      crashes with `Error in make.unique(names) : 'names' must be a
      character vector`. Hits any dataset whose symbols aren't in Omix's
      expected human/mouse/Ensembl/UniProt-style formats. CyanoOmix passes
      `ID_type = "original"`. Also covers the older item "review the regex
      heuristic for non-human gene ID casing conventions" (flagged by a test
      comment in `tests/testthat/test-generate_multiassay.R:24-27`).
- [ ] CyanoOmix #1: fix `process_rna()`'s unguarded `covariates=NULL`
      formula paste (`R/process_rna.R:73`) — crashes with "unexpected end
      of input"; `process_protein()` already guards this correctly, mirror
      that fix. No existing test exercises `covariates=NULL`.
- [ ] Guard `annotation_lookup()`'s `GENETYPE` request
      (`R/generate_multiassay.R:328-337`) and the `UNIPROT` keytype
      (`:215`): check `"GENETYPE" %in% AnnotationDbi::columns(db)` (or the
      equivalent keytype validity check for `UNIPROT`) before querying,
      falling back to NA/none instead of erroring, for OrgDb objects that
      weren't built with that table (e.g. a minimal AnnotationForge-built
      prokaryote OrgDb). Still unguarded in 1.1.3.
- [ ] CyanoOmix #4: add an organism gate / opt-out to
      `integrative_results_supervised()`/`_unsupervised()`/
      `_sparse_supervised()` so `ctd`/`disease_id` can be `NULL` and the
      internal `cell_type_enrichment()`/`OpenTarget_dataframe()` calls
      are skipped; gate `multi_omic_report()` the same way.

## Enrichment defaults and docs

- [ ] Fix the false claim in `vignettes/Omix_vignette_prokaryote.Rmd` (the
      "None of these are called automatically ... opt-in functions you
      simply don't call" paragraph, ~l.315) that EWCE/OpenTargets/etc. are
      opt-in — the actual `integrative_results_*()` entry points call them
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

## Tests and CI

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
