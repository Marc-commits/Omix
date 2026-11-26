# Optional annotation packages
#
# EnsDb.Hsapiens.v86, org.Hs.eg.db, org.Mm.eg.db and msigdbr are listed under
# Suggests: they are only needed for organism = "human"/"mouse" and are not
# installed for other organisms, e.g. bacteria with their own OrgDb package.

# Stops with an install hint if an optional package is missing.
require_optional <- function(pkg, needed_for) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    stop(
      "Package '", pkg, "' is needed for ", needed_for,
      " but is not installed. Install it, e.g. with BiocManager::install(\"",
      pkg, "\").",
      call. = FALSE
    )
  }
  invisible(TRUE)
}
