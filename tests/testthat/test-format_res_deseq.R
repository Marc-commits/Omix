mk_deseq_res <- function(ids) {
  data.frame(
    baseMean = 100, log2FoldChange = c(2, -2, 0.1),
    lfcSE = 0.1, stat = 1, pvalue = 1e-6, padj = c(1e-5, 1e-5, 0.9),
    row.names = ids
  )
}

test_that("non-Ensembl IDs are joined via feature_id (CyanoOmix #5)", {
  ids <- c("hemA", "PCC7120DELTA_RS00010", "asl0046")
  conv <- data.frame(
    gene_name = c("hemA", "PCC7120DELTA_RS00010", "asl0046"),
    gene_biotype = "protein_coding",
    feature_id = ids
  )
  out <- format_res_deseq(mk_deseq_res(ids), gene_id_conversion = conv,
                          filter_protein_coding = FALSE)
  expect_false(anyNA(out$gene_name))
  expect_setequal(out$gene_name, ids)
  expect_true(all(out$gene_type == "protein_coding"))
})

test_that("ensembl_gene_id is still preferred when present", {
  ids <- c("ENSG01", "ENSG02", "ENSG03")
  conv <- data.frame(
    ensembl_gene_id = ids, gene_name = c("A", "B", "C"),
    gene_biotype = "protein_coding", feature_id = c("x", "y", "z")
  )
  out <- format_res_deseq(mk_deseq_res(ids), gene_id_conversion = conv,
                          filter_protein_coding = FALSE)
  expect_setequal(out$gene_name, c("A", "B", "C"))
})

test_that("no join key falls back to the rownames with a warning", {
  ids <- c("hemA", "hemB", "hemC")
  conv <- data.frame(gene_name = ids, gene_biotype = "protein_coding")
  expect_warning(
    out <- format_res_deseq(mk_deseq_res(ids), gene_id_conversion = conv,
                            filter_protein_coding = FALSE),
    "no ensembl_gene_id or feature_id"
  )
  expect_setequal(out$gene_name, ids)
})
