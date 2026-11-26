test_that("a 'group' metadata column is renamed for MOFA2 (CyanoOmix #7)", {
  md <- data.frame(group = c("A", "B"), age = 1:2, row.names = c("s1", "s2"))
  expect_warning(out <- mofa_safe_metadata(md), "reserved by MOFA2")
  expect_false("group" %in% colnames(out))
  expect_equal(out$group_metadata, c("A", "B"))
  expect_equal(out$sample, c("s1", "s2"))
})

test_that("the rename avoids an existing group_metadata column", {
  md <- data.frame(group = "A", group_metadata = "x", row.names = "s1")
  out <- suppressWarnings(mofa_safe_metadata(md))
  expect_equal(out$group_metadata, "x")
  expect_equal(out$group_metadata.1, "A")
})

test_that("metadata without 'group' is unchanged apart from 'sample'", {
  md <- data.frame(condition = c("A", "B"), row.names = c("s1", "s2"))
  expect_no_warning(out <- mofa_safe_metadata(md))
  expect_equal(colnames(out), c("condition", "sample"))
})

test_that("the renamed metadata is accepted by MOFA2's setter", {
  skip_if_not_installed("MOFA2")
  set.seed(1)
  X <- list(
    mRNA = matrix(rnorm(40), 5, dimnames = list(paste0("g", 1:5), paste0("s", 1:8))),
    proteins = matrix(rnorm(40), 5, dimnames = list(paste0("p", 1:5), paste0("s", 1:8)))
  )
  obj <- suppressWarnings(suppressMessages(MOFA2::create_mofa(X)))
  md <- data.frame(group = rep(c("A", "B"), 4), row.names = paste0("s", 1:8))
  expect_error(MOFA2::samples_metadata(obj) <- cbind(md, sample = rownames(md)))
  expect_no_error(
    MOFA2::samples_metadata(obj) <- suppressWarnings(mofa_safe_metadata(md))
  )
})
