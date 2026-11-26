test_that("get_module_annotation() skips loudly for an unsupported organism", {
  expect_message(
    res <- get_module_annotation(
      gene_list = c("a_rna", "b_rna"),
      moduleColors = c("turquoise", "blue"),
      organism = "bacteria_x"
    ),
    "only supports organism"
  )
  expect_null(res)
})

test_that("get_module_annotation() defaults organism to 'human'", {
  expect_equal(eval(formals(get_module_annotation)$organism), "human")
})
