mk_synthetic_multiomics <- function(rna_ids, protein_ids, n_samples = 4) {
  rna <- matrix(sample(1:1000, length(rna_ids) * n_samples), nrow = length(rna_ids))
  rownames(rna) <- rna_ids
  colnames(rna) <- paste0("s", seq_len(n_samples))

  protein <- matrix(sample(1:1000, length(protein_ids) * n_samples), nrow = length(protein_ids))
  rownames(protein) <- protein_ids
  colnames(protein) <- paste0("s", seq_len(n_samples))

  meta <- data.frame(
    diagnosis = rep(c("A", "B"), length.out = n_samples),
    row.names = colnames(rna)
  )
  individual_metadata <- data.frame(id = colnames(rna), diagnosis = meta$diagnosis)
  qc <- data.frame(rin = stats::runif(n_samples), row.names = colnames(rna))
  map_rna <- data.frame(primary = colnames(rna), colname = colnames(rna))
  map_protein <- data.frame(primary = colnames(protein), colname = colnames(protein))

  list(
    rawdata_rna = as.data.frame(rna),
    rawdata_protein = as.data.frame(protein),
    metadata_rna = meta,
    metadata_protein = meta,
    individual_metadata = individual_metadata,
    rna_qc_data_matrix = qc,
    map_rna = map_rna,
    map_protein = map_protein
  )
}

call_generate_multiassay <- function(d, organism = "human", annotation = NULL) {
  generate_multiassay(
    rawdata_rna = d$rawdata_rna,
    rawdata_protein = d$rawdata_protein,
    individual_to_sample = FALSE,
    map_rna = d$map_rna,
    map_protein = d$map_protein,
    metadata_rna = d$metadata_rna,
    metadata_protein = d$metadata_protein,
    individual_metadata = d$individual_metadata,
    map_by_column = "id",
    rna_qc_data = TRUE,
    rna_qc_data_matrix = d$rna_qc_data_matrix,
    organism = organism,
    annotation = annotation
  )
}

# A larger synthetic multiassay with a `covariate1` colData column
# (independent of `diagnosis`, so DESeq2's model matrix stays full rank),
# suitable for exercising process_rna()'s DESeq2-based pipeline.
mk_synthetic_multiassay_for_processing <- function(organism, annotation = NULL,
                                                   n_genes = 30, n_samples = 8) {
  rna_ids <- paste0("STM", sprintf("%04d", seq_len(n_genes)))
  d <- mk_synthetic_multiomics(rna_ids, rna_ids, n_samples = n_samples)
  d$rawdata_rna[] <- matrix(
    stats::rnbinom(n_genes * n_samples, mu = 200, size = 5),
    nrow = n_genes
  )
  # deliberately not perfectly correlated with the alternating A/B
  # diagnosis pattern, or DESeq2's model matrix becomes rank-deficient
  cov <- rep(c(0, 1, 1, 0), length.out = n_samples)
  d$metadata_rna$covariate1 <- cov
  d$metadata_protein$covariate1 <- cov
  d$individual_metadata$covariate1 <- cov

  call_generate_multiassay(d, organism = organism, annotation = annotation)
}

# Runs `expr`, collecting every `message()`-class condition it emits
# (including cli::cli_alert_*) even if `expr` later errors -- used to
# assert on process_rna()'s output without depending on its final return
# value succeeding end-to-end (its last step, reassembling the
# MultiAssayExperiment sampleMap, is sensitive to the installed
# MultiAssayExperiment version and unrelated to what these tests check).
capture_messages_even_on_error <- function(expr) {
  msgs <- character()
  tryCatch(
    withCallingHandlers(
      expr,
      message = function(m) {
        msgs <<- c(msgs, conditionMessage(m))
        invokeRestart("muffleMessage")
      }
    ),
    error = function(e) NULL
  )
  msgs
}
