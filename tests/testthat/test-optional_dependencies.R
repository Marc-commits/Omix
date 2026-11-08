test_that("require_optional() stops with an install hint for a missing package", {
  expect_error(
    require_optional("notInstalledPackageXyz", "testing"),
    "needed for testing but is not installed"
  )
})

test_that("require_optional() passes for an installed package", {
  expect_true(require_optional("stats", "testing"))
})

test_that("mofa_use_basilisk() defaults to TRUE and follows the option", {
  old <- options(omix.use_basilisk = NULL)
  on.exit(options(old))
  expect_true(mofa_use_basilisk())
  options(omix.use_basilisk = FALSE)
  expect_false(mofa_use_basilisk())
  options(omix.use_basilisk = TRUE)
  expect_true(mofa_use_basilisk())
})
