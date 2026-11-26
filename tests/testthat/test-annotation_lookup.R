# A fake minimal OrgDb: SYMBOL keytype only, no GENETYPE column, no UNIPROT
mock_minimal_orgdb <- function() {
  local_mocked_bindings(
    keytypes = function(x) c("SYMBOL", "GID"),
    columns = function(x) c("SYMBOL", "GID"),
    select = function(x, keys, columns, keytype, ...) {
      known <- c("hemA", "asl0046")
      k <- keys[keys %in% known]
      if (length(k) == 0) stop("None of the keys entered are valid keys")
      data.frame(SYMBOL = k, GID = seq_along(k))
    },
    .package = "AnnotationDbi",
    .env = parent.frame()
  )
}
src <- list(db = "fake", class = "OrgDb")

test_that("a missing GENETYPE column gives NA biotypes, not an error", {
  mock_minimal_orgdb()
  expect_warning(
    res <- annotation_lookup(src, c("hemA", "asl0046", "unknown1"), "SYMBOL"),
    "no 'GENETYPE' column"
  )
  expect_equal(res$gene_name, c("hemA", "asl0046", "unknown1"))
  expect_true(all(is.na(res$gene_biotype)))
})

test_that("a missing UNIPROT keytype keeps the original IDs", {
  mock_minimal_orgdb()
  expect_warning(
    res <- annotation_lookup(src, c("P04637", "Q3LRJ0"), "UNIPROT"),
    "no 'UNIPROT' keytype"
  )
  expect_equal(res$gene_name, c("P04637", "Q3LRJ0"))
})

test_that("no valid keys at all degrades instead of erroring", {
  mock_minimal_orgdb()
  msgs <- character()
  res <- withCallingHandlers(
    annotation_lookup(src, c("x1", "x2"), "SYMBOL"),
    warning = function(w) {
      msgs <<- c(msgs, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
  expect_true(any(grepl("lookup by 'SYMBOL' failed", msgs)))
  expect_equal(res$gene_name, c("x1", "x2"))
})
