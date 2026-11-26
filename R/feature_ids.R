# Undo the view suffixes that are appended to feature names during
# integration: MOFA2 suffixes features present in both views with
# "_mRNA"/"_proteins", and Omix's network/module code appends "_rna"/
# "_protein". Only a literal trailing suffix is removed, so IDs that contain
# underscores themselves (RefSeq locus tags such as PCC7120DELTA_RS00010,
# paralog symbols such as cas6_2) stay intact. The previous
# sub("\\_.*", "", x) cut everything from the first underscore.
strip_view_suffix <- function(x) {
  sub("_(mRNA|proteins|rna|protein)$", "", x)
}
