# integrative_results_unsupervised() with the organism-specific steps
# (EWCE cell types, TF enrichment, Open Targets) switched off or on. All
# building blocks are mocked, so this only tests the gating logic.

local_unsupervised_mocks <- function(calls, env = parent.frame()) {
  record <- function(name, value = list()) {
    force(name); force(value)
    function(...) {
      calls[[name]] <- c(calls[[name]], 1L)
      value
    }
  }
  r2 <- matrix(c(10, 5, 8, 2), nrow = 2,
               dimnames = list(c("Factor1", "Factor2"), c("mRNA", "proteins")))
  testthat::local_mocked_bindings(
    get_variance_explained = function(...) list(r2_per_factor = list(group1 = r2)),
    samples_metadata = function(...) data.frame(sample = "s1"),
    .package = "MOFA2", .env = env
  )
  testthat::local_mocked_bindings(
    MOFA_get_relevant_factor = function(...) "Factor1",
    MOFA_sign_relevant_factor = function(...) "positive",
    extract_weigths = function(...) list(weights = list(
      ranked_weights_positive = list(), ranked_weights_negative = list())),
    multiomics_network = function(...) list(graph = NULL),
    communities_network = function(...) list(communities = list(c1 = c("geneA_rna", "geneB_protein"))),
    pathway_analysis_enrichr = function(...) list(),
    multiomics_modules = function(...) list(modules_eigen_value = data.frame()),
    correlation_heatmap = function(...) NULL,
    cell_type_enrichment = record("cell_type_enrichment", "ct"),
    Transcription_Factor_enrichment = record("Transcription_Factor_enrichment", "tf"),
    OpenTarget_dataframe = record("OpenTarget_dataframe", "ot_df"),
    plot_OpenTarget = record("plot_OpenTarget", "ot_plot"),
    .env = env
  )
}

dummy_multiassay <- function() {
  MultiAssayExperiment::MultiAssayExperiment(
    metadata = list(integration = list(MOFA = "model"))
  )
}

run_unsupervised <- function(...) {
  suppressMessages(integrative_results_unsupervised(
    dummy_multiassay(), integration_model = "MOFA", pseudotime_analysis = FALSE, ...
  ))
}

test_that("NULL ctd/TF_fp/disease_id skip the organism-specific steps", {
  calls <- new.env()
  local_unsupervised_mocks(calls)
  res <- run_unsupervised(disease_id = NULL)
  expect_null(calls$cell_type_enrichment)
  expect_null(calls$Transcription_Factor_enrichment)
  expect_null(calls$OpenTarget_dataframe)
  expect_null(calls$plot_OpenTarget)

  ir <- MultiAssayExperiment::metadata(res)$integrative_results$MOFA
  expect_true(all(c("cell_type", "TF", "OpenTargets") %in% names(ir)))
  expect_null(ir$cell_type)
  expect_null(ir$TF)
  expect_null(ir$OpenTargets)
  expect_type(ir$functional_enrichment, "list")
})

test_that("ctd/TF_fp/disease_id given still run the steps", {
  calls <- new.env()
  local_unsupervised_mocks(calls)
  res <- run_unsupervised(disease_id = "MONDO_0004975", TF_fp = "tf.gmt", ctd = list())
  expect_length(calls$cell_type_enrichment, 1) # only $positive is computed (pre-existing)
  expect_length(calls$Transcription_Factor_enrichment, 2)
  expect_length(calls$OpenTarget_dataframe, 4)
  expect_length(calls$plot_OpenTarget, 4)

  ir <- MultiAssayExperiment::metadata(res)$integrative_results$MOFA
  expect_equal(ir$cell_type$positive, "ct")
  expect_equal(ir$TF$negative, "tf")
  expect_equal(ir$OpenTargets$negative$protein$plot, "ot_plot")
})

test_that("optional_step_enabled() reports skipped steps", {
  expect_false(suppressMessages(optional_step_enabled(NULL, "x")))
  expect_true(optional_step_enabled("a", "x"))
})
