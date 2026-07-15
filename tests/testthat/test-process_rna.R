test_that("protein_coding filtering is skipped (with a warning) when gene_biotype is absent", {
  skip_if_not_installed("DESeq2")
  ma <- mk_synthetic_multiassay_for_processing(organism = "bacteria_x")

  msgs <- capture_messages_even_on_error(
    process_rna(ma,
      transformation = "log2", protein_coding = TRUE, filter = TRUE,
      min_count = 1, min_sample = 0.1, dependent = "diagnosis", levels = NULL,
      covariates = "covariate1", batch_correction = FALSE, batch = NULL
    )
  )

  expect_true(any(grepl("No gene_biotype annotation available", msgs)))
  # none of the 30 synthetic genes should have been dropped by the
  # (skipped) protein_coding filter -- only by the QC count filter, which
  # a min_count = 1 / min_sample = 0.1 threshold shouldn't touch either
  expect_true(any(grepl("0 / 30 genes were dropped", msgs, fixed = TRUE)))
})

test_that("protein_coding filtering still runs normally when gene_biotype is present", {
  skip_if_not_installed("DESeq2")
  ann <- data.frame(
    gene_name = paste0("gene", seq_len(30)),
    gene_biotype = rep(c("protein_coding", "ncRNA"), c(20, 10)),
    row.names = paste0("STM", sprintf("%04d", seq_len(30)))
  )
  ma <- mk_synthetic_multiassay_for_processing(organism = "bacteria_x", annotation = ann)

  msgs <- capture_messages_even_on_error(
    process_rna(ma,
      transformation = "log2", protein_coding = TRUE, filter = TRUE,
      min_count = 1, min_sample = 0.1, dependent = "diagnosis", levels = NULL,
      covariates = "covariate1", batch_correction = FALSE, batch = NULL
    )
  )

  expect_false(any(grepl("No gene_biotype annotation available", msgs)))
  expect_true(any(grepl("10 / 30 non protein coding genes were dropped", msgs)))
  expect_true(any(grepl("20 protein coding genes kept for analysis", msgs)))
})
