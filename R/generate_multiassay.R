################################################################################
#' Generate a MultiAssayExperiment object from multiple single-omics data
#'
#' Generate a MultiAssayExperiment object from single-omics data matrix
#' and metadata. Currently supports transcriptomics and proteomics data only.
#'
#' @param rawdata_rna A data-frame containing raw RNA count where rows and
#' columns correspond to genes and samples respectively
#' @param rawdata_protein A data-frame containing raw protein abundance where
#' rows and columns correspond to genes and samples respectively
#' @param individual_to_sample Logical whether individual ID and sample names in
#' raw data matrices are the same. If they are different, `mpa_rna` and
#'  `map_protein`
#' dataframes should be provided. Default to `FALSE`.
#' @param map_rna A data-frame of two columns named `primary` and `colname`
#' where primary should contain unique ID name with a link to individual
#' metadata and colname is the column names of the `rawdata_rna` data-frame
#' @param map_protein A data-frame of two columns named `primary` and `colname`
#' where primary should contain unique ID name with a link to individual
#' metadata and colname is the column names of the `rawdata_protein` data-frame
#' @param metadata_rna A data-frame containing `rna` assay specific metadata
#' where rownames are same as the colnames of `rawdata_rna` data.frame
#' @param metadata_protein A data-frame containing `protein` assay specific
#' metadata where rownames are same as the colnames of `rawdata_protein`
#' data.frame
#' @param individual_metadata A data-frame containing sample level metadata
#' @param map_by_column The common column name to link `metadata_rna`
#' and `metadata_protein` to the `individual_metadata`
#' @param rna_qc_data Logical whether to add rna QC data.
#' @param rna_qc_data_matrix A data.frame containing RNA qc level data where
#' rownames are same as the colnames of `rawdata_rna` data.frame.
#' @param organism The organism type for transcripts and proteins. Possible
#' values are `human` (uses `EnsDb.Hsapiens.v86`), `mouse` (uses
#' `org.Mm.eg.db`; both are optional packages, install the one you need), or
#' the name of any other installed Bioconductor
#' annotation package following the `org.*.eg.db` naming convention (e.g.
#' `"org.EcK12.eg.db"` for *E. coli* K-12). Such a package can be built for
#' any organism, including bacteria/archaea with no existing package, via
#' `AnnotationForge::makeOrgPackage()`. Default to `human`.
#' @param annotation Optional data.frame used as a fallback gene/protein
#' annotation source when `organism` does not resolve to `human`, `mouse`,
#' or an installed annotation package (e.g. a species with no `org.*.eg.db`
#' package available, annotated instead via Prokka/Bakta/eggNOG-mapper).
#' Rownames must match the raw RNA/protein IDs (`rownames(rawdata_rna)` /
#' `rownames(rawdata_protein)`); recognised columns are `gene_name` and,
#' optionally, `gene_biotype`. Ignored when `organism` resolves to an
#' annotation package. Default to `NULL`.
#'
#' @return a MultiAssayExperiment object
#'
#' @family Pre-processing
#'
#' @importFrom MultiAssayExperiment MultiAssayExperiment listToMap colData
#' @importFrom SummarizedExperiment SummarizedExperiment
#' @importFrom magrittr set_names
#' @importFrom cli cli_alert_danger cli_alert_warning style_bold cli_alert_success
#' @export
generate_multiassay <- function(rawdata_rna,
                                rawdata_protein,
                                individual_to_sample = FALSE,
                                map_rna,
                                map_protein,
                                metadata_rna,
                                metadata_protein,
                                individual_metadata,
                                map_by_column,
                                rna_qc_data = FALSE,
                                rna_qc_data_matrix,
                                organism = "human",
                                annotation = NULL) {
  if (!all(colnames(rawdata_rna) == rownames(metadata_rna))) {
    stop(cli::cli_alert_danger(
      paste("The columns in the", cli::style_bold("rawdata_rna"),
        "should be same as the rows in", cli::style_bold("metadata_rna"),
        sep = " "
      )
    ))
  }

  if (!all(colnames(rawdata_protein) == rownames(metadata_protein))) {
    stop(cli::cli_alert_danger(
      paste("The columns in the", cli::style_bold("rawdata_protein"),
        "should be same as the rows in", cli::style_bold("metadata_protein"),
        sep = " "
      )
    ))
  }

  if (!all(colnames(map_rna) == c("primary", "colname"))) {
    stop(cli::cli_alert_danger(
      paste(cli::style_bold("primary"), "and", cli::style_bold("colname"),
        "columns are not found in", cli::style_bold("map_rna!"),
        sep = " "
      )
    ))
  }

  if (!all(colnames(map_protein) == c("primary", "colname"))) {
    stop(cli::cli_alert_danger(
      paste(cli::style_bold("primary"), "and", cli::style_bold("colname"),
        "columns are not found in", cli::style_bold("map_protein!"),
        sep = " "
      )
    ))
  }

  if (!all(colnames(rawdata_rna) == rownames(rna_qc_data_matrix))) {
    stop(cli::cli_alert_danger(
      paste("The columns in the", cli::style_bold("rawdata_rna"),
        "should be same as the rows in", cli::style_bold("rna_qc_data_matrix"),
        sep = " "
      )
    ))
  }


  individual_metadata <- as.data.frame(individual_metadata)

  if (individual_to_sample == TRUE) {
    map_rna <- data.frame(
      primary = colnames(rawdata_rna),
      colname = colnames(rawdata_rna),
      stringsAsFactors = FALSE
    )

    map_protein <- data.frame(
      primary = colnames(rawdata_protein),
      colname = colnames(rawdata_protein),
      stringsAsFactors = FALSE
    )
  }

  if (individual_to_sample == FALSE) {
    map_l <- list(
      data.frame(map_rna),
      data.frame(map_protein)
    )
  }

  names(map_l) <- c(
    "rna_raw",
    "protein_raw"
  )
  suppressMessages({
  dfmap <- MultiAssayExperiment::listToMap(map_l)

  rawdata_rna <- rawdata_rna[!duplicated(rownames(rawdata_rna)), ]

  rna_id_type <- get_ID_type(rownames(rawdata_rna))
  se_rna <- SummarizedExperiment::SummarizedExperiment(
    assays = list("rna_raw" = rawdata_rna),
    colData = S4Vectors::DataFrame(metadata_rna),
    rowData = magrittr::set_names(
      S4Vectors::DataFrame(gene_id = as.character(rownames(rawdata_rna))),
      rna_id_type
    )
  )
  })

  se_rna@metadata$metadata <- metadata_rna

  annotation_source <- resolve_annotation_source(organism, annotation)

  if (rna_id_type %in% c("ensembl_gene_id", "gene_name")) {
    rna_values <- se_rna@elementMetadata@listData[[rna_id_type]]
    rna_keytype <- if (rna_id_type == "ensembl_gene_id") {
      if (annotation_source$class == "EnsDb") "GENEID" else "ENSEMBL"
    } else {
      "SYMBOL"
    }

    if (rna_id_type == "ensembl_gene_id") {
      cli::cli_alert_success("Ensembl ID conversion to gene symbol")
    }
    cli::cli_alert_success("Retrieval of gene biotype")

    looked_up <- annotation_lookup(annotation_source, rna_values, rna_keytype)

    # For `rna_id_type == "gene_name"` this overwrites the constructor's
    # raw-ID default with the resolved value (a no-op when the raw ID was
    # already the correct symbol, e.g. human/mouse; a real translation
    # when it wasn't, e.g. a locus tag matched against an `annotation`
    # table).
    se_rna@elementMetadata@listData$gene_name <- looked_up$gene_name
    se_rna@elementMetadata@listData$gene_biotype <- looked_up$gene_biotype
  }

  if (rna_qc_data) {
    se_rna@metadata$rna_qc_data <- rna_qc_data_matrix[colnames(rawdata_rna), ]
  }

  rawdata_protein <- rawdata_protein[!duplicated(rownames(rawdata_protein)), ]
  protein_id_type <- get_ID_type(rownames(rawdata_protein))

  suppressMessages({
    se_protein <- SummarizedExperiment::SummarizedExperiment(
    assays = list("protein_raw" = rawdata_protein),
    colData = S4Vectors::DataFrame(metadata_protein),
    rowData = magrittr::set_names(
      S4Vectors::DataFrame(gene_id = as.character(rownames(rawdata_protein))),
      protein_id_type
    )
  )

  se_protein@metadata$metadata <- metadata_protein
  })

  if (protein_id_type %in% c("uniprot_id", "gene_name")) {
    protein_values <- se_protein@elementMetadata@listData[[protein_id_type]]

    if (protein_id_type == "uniprot_id") {
      # ID conversion using biomart
      cli::cli_alert_success("UniProt ID conversion to gene name ")
      protein_values <- sub("\\-.*", "", protein_values)
      protein_keytype <- if (annotation_source$class == "EnsDb") "UNIPROTID" else "UNIPROT"
    } else {
      protein_keytype <- "SYMBOL"
    }

    looked_up <- annotation_lookup(annotation_source, protein_values, protein_keytype)

    # See the equivalent RNA branch above: for `protein_id_type ==
    # "gene_name"` this is a no-op when the raw ID was already correct,
    # and a real translation (e.g. from a supplied `annotation` table)
    # when it wasn't.
    se_protein@elementMetadata@listData$gene_name <- looked_up$gene_name
  }


  rownames(individual_metadata) <- individual_metadata[, map_by_column]
  suppressMessages({
  multiassay <- MultiAssayExperiment::MultiAssayExperiment(
    list(
      "rna_raw" = se_rna,
      "protein_raw" = se_protein
    ),
    colData = S4Vectors::DataFrame(individual_metadata),
    sampleMap = S4Vectors::DataFrame(dfmap)
  )
  })

  cli::cli_alert_success("RNA raw data loaded")
  print(se_rna)
  cli::cli_alert_success("Protein raw data loaded")
  print(se_protein)
  cli::cli_alert_success("MultiAssayExperiment object generated!")

  return(multiassay)
}


#' Resolve the gene/protein annotation source for a given organism
#'
#' `"human"` and `"mouse"` map to the package's built-in annotation
#' databases. Any other string is treated as the name of an installed
#' Bioconductor annotation package (the `org.*.eg.db` naming convention,
#' which also covers packages built with
#' `AnnotationForge::makeOrgPackage()` for organisms with no existing
#' package, e.g. most bacteria/archaea). If that doesn't resolve either,
#' falls back to a user-supplied `annotation` data.frame, or, failing
#' that, to no annotation at all (with a warning) so the pipeline can
#' still complete.
#'
#' @param organism Organism string, see `generate_multiassay()`.
#' @param annotation Optional fallback annotation data.frame, see
#' `generate_multiassay()`.
#'
#' @return A list with `db` (the EnsDb/OrgDb object, or `NULL`) and
#' `class` (one of `"EnsDb"`, `"OrgDb"`, `"table"`, `"none"`).
#'
#' @keywords internal
resolve_annotation_source <- function(organism, annotation) {
  if (organism == "human") {
    require_optional("EnsDb.Hsapiens.v86", "organism = \"human\"")
    return(list(db = EnsDb.Hsapiens.v86::EnsDb.Hsapiens.v86, class = "EnsDb"))
  }
  if (organism == "mouse") {
    require_optional("org.Mm.eg.db", "organism = \"mouse\"")
    return(list(db = org.Mm.eg.db::org.Mm.eg.db, class = "OrgDb"))
  }
  if (requireNamespace(organism, quietly = TRUE)) {
    cli::cli_alert_success(paste0(
      "Using annotation package '", organism, "'"
    ))
    return(list(
      db = getExportedValue(organism, organism),
      class = "OrgDb"
    ))
  }
  if (!is.null(annotation)) {
    cli::cli_alert_success(
      "Using user-supplied `annotation` table for gene symbol/biotype"
    )
    return(list(db = NULL, class = "table", annotation = annotation))
  }
  cli::cli_alert_warning(paste0(
    "Organism '", organism, "' is not \"human\"/\"mouse\", is not an ",
    "installed Bioconductor annotation package, and no `annotation` ",
    "table was supplied -- gene names/biotypes will not be populated. ",
    "Install a Bioconductor org.*.eg.db package for this organism, ",
    "build one with AnnotationForge::makeOrgPackage(), or pass ",
    "`annotation=`."
  ))
  return(list(db = NULL, class = "none"))
}


#' Look up gene symbol and biotype from a resolved annotation source
#'
#' Dispatches to `AnnotationDbi::select()` on an EnsDb/OrgDb object, or to
#' a user-supplied annotation table, depending on the `class` of
#' `annotation_source` (see `resolve_annotation_source()`). Always
#' returns `gene_name`/`gene_biotype` vectors aligned to `keys`, so
#' callers don't need to branch on the annotation source themselves.
#'
#' @param annotation_source List returned by `resolve_annotation_source()`.
#' @param keys Character vector of raw RNA/protein IDs to look up.
#' @param keytype `AnnotationDbi` keytype to query `annotation_source$db`
#' with when its class is `"EnsDb"`/`"OrgDb"` (e.g. `"GENEID"`,
#' `"ENSEMBL"`, `"SYMBOL"`, `"UNIPROTID"`, `"UNIPROT"`). Ignored for the
#' `"table"`/`"none"` classes, which match by `annotation` rownames.
#'
#' @return A list with `gene_name` and `gene_biotype` character vectors,
#' the same length/order as `keys`.
#'
#' @keywords internal
annotation_lookup <- function(annotation_source, keys, keytype) {
  if (annotation_source$class %in% c("EnsDb", "OrgDb")) {
    biotype_col <- if (annotation_source$class == "EnsDb") {
      "GENEBIOTYPE"
    } else {
      "GENETYPE"
    }
    df <- suppressMessages(AnnotationDbi::select(annotation_source$db,
      keys = keys,
      keytype = keytype,
      columns = c("SYMBOL", biotype_col)
    ))
    idx <- match(keys, df[[keytype]])
    gene_biotype <- df[[biotype_col]][idx]
    if (annotation_source$class == "OrgDb") {
      # normalise NCBI's GENETYPE (e.g. "protein-coding") to the
      # "protein_coding" convention used by EnsDb's GENEBIOTYPE and
      # matched elsewhere in the pipeline (e.g. process_rna()).
      gene_biotype <- gsub("-", "_", gene_biotype)
    }
    gene_name <- df$SYMBOL[idx]
    # fall back to the raw key when the annotation source has no match,
    # rather than losing it to NA (e.g. a locus tag with no SYMBOL hit)
    gene_name[is.na(gene_name)] <- keys[is.na(gene_name)]
    return(list(
      gene_name = gene_name,
      gene_biotype = gene_biotype
    ))
  }

  if (annotation_source$class == "table") {
    ann <- annotation_source$annotation
    idx <- match(keys, rownames(ann))

    gene_name <- if ("gene_name" %in% colnames(ann)) {
      ann$gene_name[idx]
    } else {
      rep(NA_character_, length(keys))
    }
    gene_name[is.na(gene_name)] <- keys[is.na(gene_name)]

    gene_biotype <- if ("gene_biotype" %in% colnames(ann)) {
      ann$gene_biotype[idx]
    } else {
      rep(NA_character_, length(keys))
    }

    return(list(gene_name = gene_name, gene_biotype = gene_biotype))
  }

  # class == "none": no annotation source at all
  list(gene_name = keys, gene_biotype = rep(NA_character_, length(keys)))
}
