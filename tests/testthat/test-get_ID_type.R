test_that("mixed-case symbols and locus tags are gene names (CyanoOmix #6)", {
  expect_equal(get_ID_type(c("hemA", "asl0046", "PCC7120DELTA_RS00010", "cas6_2")),
               "gene_name")
  expect_equal(get_ID_type(c("asl0046", "hemA", "hetY", "alr2298", "ruvC")),
               "gene_name")
  expect_equal(get_ID_type(c("TP53", "BRCA1", "C1orf112")), "gene_name")
})

test_that("Ensembl, Entrez and UniProt IDs are still recognised", {
  expect_equal(get_ID_type(c("ENSG00000141510", "ENSG00000012048")),
               "ensembl_gene_id")
  expect_equal(get_ID_type(c("7157", "672")), "entrez_gene_id")
  expect_equal(get_ID_type(c("P04637", "P38398;Q3LRJ0")), "uniprot_id")
})

test_that("the type is decided by the majority, not the first ID", {
  expect_equal(get_ID_type(c("12345", "hemA", "hemB", "asl0046")), "gene_name")
})

test_that("unclassifiable IDs warn and return not_identified", {
  expect_warning(res <- get_ID_type(c("1abc", "2-x", NA, "")),
                 "ID type not identified")
  expect_equal(res, "not_identified")
})

test_that("get_ID_names keeps IDs when the mapping column is missing", {
  d <- mk_synthetic_multiomics(
    rna_ids = c("asl0046", "hemA"), protein_ids = c("asl0046", "hemA")
  )
  ma <- suppressWarnings(call_generate_multiassay(
    d, organism = "bacteria_x",
    annotation = data.frame(gene_name = c("asl0046", "hemA"),
                            gene_biotype = "protein_coding",
                            row.names = c("asl0046", "hemA"))
  ))
  expect_warning(
    ids <- get_ID_names(ma, id = c("asl0046", "hemA"), omic = "protein",
                        from = "uniprot_id", to = "gene_name"),
    "keeping the original IDs"
  )
  expect_equal(ids, c("asl0046", "hemA"))
})

test_that("get_multimodal_object() keeps locus-tag IDs instead of crashing", {
  ids <- c("asl0046", "hemA", "PCC7120DELTA_RS00010")
  d <- mk_synthetic_multiomics(rna_ids = ids, protein_ids = ids)
  ma <- suppressWarnings(call_generate_multiassay(d, organism = "bacteria_x"))
  # stand-ins for the processed slots (plain matrices, as process_*() makes)
  ma <- suppressWarnings(c(ma,
    rna_processed = as.matrix(SummarizedExperiment::assay(ma[["rna_raw"]])),
    mapFrom = "rna_raw"))
  ma <- suppressWarnings(c(ma,
    protein_processed = as.matrix(SummarizedExperiment::assay(ma[["protein_raw"]])),
    mapFrom = "protein_raw"))
  res <- suppressWarnings(get_multimodal_object(ma, ID_type = "gene_name"))
  expect_equal(rownames(res$multimodal_object[[1]]), ids)
  expect_equal(rownames(res$multimodal_object[[2]]), ids)
})
