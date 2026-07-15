test_that("organism = 'human' populates gene_name/gene_biotype via EnsDb (regression)", {
  skip_if_not_installed("EnsDb.Hsapiens.v86")
  d <- mk_synthetic_multiomics(
    rna_ids = c("ENSG00000141510", "ENSG00000012048"), # TP53, BRCA1
    protein_ids = c("P04637", "P38398")
  )
  ma <- call_generate_multiassay(d, organism = "human")
  rd <- SummarizedExperiment::rowData(ma[["rna_raw"]])

  expect_setequal(colnames(rd), c("ensembl_gene_id", "gene_name", "gene_biotype"))
  expect_equal(unname(rd$gene_name), c("TP53", "BRCA1"))
  expect_true(all(rd$gene_biotype == "protein_coding"))
})

test_that("organism = 'mouse' resolves via org.Mm.eg.db with a corrected GENETYPE column", {
  # Prior to this change, the mouse path requested EnsDb-only columns
  # ("GENEBIOTYPE"/"UNIPROTID") against org.Mm.eg.db, an OrgDb -- which
  # doesn't have them. This is a regression test for that fix.
  skip_if_not_installed("org.Mm.eg.db")
  d <- mk_synthetic_multiomics(
    rna_ids = c("ENSMUSG00000059552", "ENSMUSG00000017146"), # Trp53, Brca1
    protein_ids = c("Trp53", "Brca1")
  )
  # the mixed-case protein symbols don't match get_ID_type()'s regex
  # heuristic (a pre-existing, unrelated limitation) and are classified
  # "not_identified"; suppress that expected warning to keep the test
  # focused on the RNA/GENETYPE fix under test.
  ma <- suppressWarnings(call_generate_multiassay(d, organism = "mouse"))
  rd <- SummarizedExperiment::rowData(ma[["rna_raw"]])

  expect_equal(unname(rd$gene_name), c("Trp53", "Brca1"))
  expect_true(all(rd$gene_biotype == "protein_coding"))
})

test_that("organism resolves to any installed org.*.eg.db package (generic OrgDb path)", {
  # Reuses org.Hs.eg.db (already a hard dependency) purely as a stand-in
  # for a bacterial annotation package like org.EcK12.eg.db, so this test
  # needs no extra dependency to exercise the dynamic-package-load path.
  skip_if_not_installed("org.Hs.eg.db")
  d <- mk_synthetic_multiomics(
    rna_ids = c("TP53", "BRCA1"),
    protein_ids = c("TP53", "BRCA1")
  )
  expect_message(
    ma <- call_generate_multiassay(d, organism = "org.Hs.eg.db"),
    "Using annotation package 'org.Hs.eg.db'"
  )
  rd <- SummarizedExperiment::rowData(ma[["rna_raw"]])
  expect_true(all(rd$gene_biotype == "protein_coding"))
})

test_that("an unresolvable organism with a supplied annotation table populates gene_name/gene_biotype", {
  d <- mk_synthetic_multiomics(
    rna_ids = c("STM0001", "STM0002"),
    protein_ids = c("STM0001", "STM0002")
  )
  ann <- data.frame(
    gene_name = c("dnaA", "recA"),
    gene_biotype = c("protein_coding", "protein_coding"),
    row.names = c("STM0001", "STM0002")
  )

  expect_message(
    ma <- call_generate_multiassay(d, organism = "bacteria_x", annotation = ann),
    "Using user-supplied `annotation` table"
  )
  rd <- SummarizedExperiment::rowData(ma[["rna_raw"]])
  expect_equal(unname(rd$gene_name), c("dnaA", "recA"))
  expect_equal(unname(rd$gene_biotype), c("protein_coding", "protein_coding"))
})

test_that("an unresolvable organism with no annotation warns but does not error", {
  d <- mk_synthetic_multiomics(
    rna_ids = c("STM0001", "STM0002"),
    protein_ids = c("STM0001", "STM0002")
  )

  expect_message(
    ma <- call_generate_multiassay(d, organism = "bacteria_x"),
    "gene names/biotypes will not be populated"
  )
  rd <- SummarizedExperiment::rowData(ma[["rna_raw"]])
  expect_equal(unname(rd$gene_name), c("STM0001", "STM0002"))
  expect_true(all(is.na(rd$gene_biotype)))
})

test_that("organism naming an uninstalled annotation package still degrades gracefully", {
  d <- mk_synthetic_multiomics(
    rna_ids = c("STM0001", "STM0002"),
    protein_ids = c("STM0001", "STM0002")
  )

  expect_message(
    ma <- call_generate_multiassay(d, organism = "org.NotARealPackage.eg.db"),
    "is not an installed Bioconductor annotation package"
  )
  expect_s4_class(ma, "MultiAssayExperiment")
})
