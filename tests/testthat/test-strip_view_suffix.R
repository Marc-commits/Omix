test_that("only literal view suffixes are stripped (CyanoOmix #8)", {
  expect_equal(
    strip_view_suffix(c("PCC7120DELTA_RS00010", "cas6_2", "cas6_2_mRNA",
                        "cas6_2_proteins", "hemA_rna", "hemA_protein",
                        "ENSG00000141510")),
    c("PCC7120DELTA_RS00010", "cas6_2", "cas6_2", "cas6_2", "hemA", "hemA",
      "ENSG00000141510")
  )
})

test_that("extract_weigths() keeps underscore-containing IDs", {
  ids <- c("PCC7120DELTA_RS00010", "cas6_2_mRNA", "hemA", "asl0046")
  w <- c(3, 2.5, -3, 0)
  fake_weights <- function(object, views, factors, ...) {
    feats <- if (views == "mRNA") ids else sub("_mRNA$", "_proteins", ids)
    list(matrix(w, ncol = 1, dimnames = list(feats, "Factor1")))
  }
  local_mocked_bindings(get_weights = fake_weights, .package = "MOFA2")
  # threshold is rescaled to mean + threshold * sd of the RNA weights
  res <- extract_weigths(model = NULL, factor = 1, threshold = 0.1)
  expect_setequal(res$weights_df$rna$Feature, c("PCC7120DELTA_RS00010", "cas6_2",
                                               "hemA", "asl0046"))
  expect_true("PCC7120DELTA_RS00010" %in% res$weights$ranked_weights_positive$rna)
})
