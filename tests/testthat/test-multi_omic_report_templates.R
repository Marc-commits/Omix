# The organism-specific sections of the multi_omic_report() templates
# (cell types, TF enrichment, Open Targets) are hidden when their results are
# NULL. Knits only those sections, so no full integration result is needed.

template_dir <- function() {
  system.file("rmarkdown", "templates", "multi_omic", package = "Omix")
}

gated_sections <- function(lines) {
  keep <- logical(length(lines))
  gated <- FALSE
  for (i in seq_along(lines)) {
    if (startsWith(lines[i], "## ")) {
      gated <- i > 1 && grepl("^```\\{asis, echo=show_", lines[i - 1])
      if (gated) keep[i - 1] <- TRUE
    }
    keep[i] <- gated
  }
  lines[keep]
}

knit_sections <- function(file, setup) {
  lines <- gated_sections(readLines(file.path(template_dir(), file)))
  expect_gt(length(lines), 0)
  src <- c("```{r, include=FALSE}", setup, "```", "", lines)
  old <- options(knitr.duplicate.label = "allow")
  on.exit(options(old), add = TRUE)
  dir <- tempfile("knit_")
  dir.create(dir)
  owd <- setwd(dir) # knitr writes figures relative to the cwd
  on.exit(setwd(owd), add = TRUE)
  paste(knitr::knit(text = src, quiet = TRUE, envir = new.env()), collapse = "\n")
}

templates <- c("skeleton.Rmd", "skeleton2.Rmd", "skeleton3.Rmd", "skeleton4.Rmd", "skeleton5.Rmd")

test_that("templates hide the organism-specific sections when results are NULL", {
  for (f in templates) {
    md <- knit_sections(f, c(
      "show_cell_type <- FALSE", "show_TF <- FALSE", "show_OpenTargets <- FALSE"
    ))
    expect_false(grepl("Cell type enrichment|Transcription Factor|Open Targets|Error", md), label = f)
  }
})

test_that("the footer stays outside every chunk, so it is always shown", {
  for (f in templates) {
    lines <- readLines(file.path(template_dir(), f))
    in_chunk <- cumsum(startsWith(lines, "```")) %% 2 == 1
    footer <- grep("Omix v`r", lines, fixed = TRUE)
    expect_length(footer, 1)
    expect_false(in_chunk[footer], label = f)
  }
})

test_that("templates still show the sections when results exist", {
  for (f in templates) {
    md <- knit_sections(f, c(
      "show_cell_type <- TRUE", "show_TF <- FALSE", "show_OpenTargets <- TRUE",
      "cluster <- 'C1'",
      "cell_type <- list(positive = list(plots = 'CT_POS'), negative = list(plots = 'CT_NEG'),",
      "                  C1 = list(up = list(plots = 'CT_POS'), down = list(plots = 'CT_NEG')))",
      "ot <- list(rna = list(plot = 'OT_RNA'), protein = list(plot = 'OT_PROT'))",
      "OpenTargets <- list(positive = ot, negative = ot, C1 = list(up = ot, down = ot))"
    ))
    expect_match(md, "## Cell type enrichment", fixed = TRUE, label = f)
    expect_match(md, "CT_NEG", fixed = TRUE, label = f)
    expect_match(md, "## Open Targets", fixed = TRUE, label = f)
    expect_match(md, "OT_PROT", fixed = TRUE, label = f)
    expect_false(grepl("Transcription Factor", md), label = f)
  }
})
