#' Check whether an optional, organism-specific analysis step should run
#'
#' Cell type enrichment (EWCE `ctd`), transcription factor enrichment
#' (`TF_fp`) and the Open Targets queries (`disease_id`) only make sense for
#' human/mouse data. Passing `NULL` for their argument skips the step.
#'
#' @param value argument value; `NULL` switches the step off
#' @param step human-readable step name for the log message
#'
#' @return `TRUE` if the step should run, `FALSE` otherwise
#' @noRd
optional_step_enabled <- function(value, step) {
  if (is.null(value)) {
    cli::cli_text(paste0("Skipping ", step, " (argument is NULL)."))
    return(FALSE)
  }
  TRUE
}
