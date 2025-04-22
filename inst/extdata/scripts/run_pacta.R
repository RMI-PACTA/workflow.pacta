logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))

if (
  is.null(Sys.getenv("ANALYSIS_OUTPUT_DIR")) ||
    Sys.getenv("ANALYSIS_OUTPUT_DIR") == ""
) {
  log_error("ANALYSIS_OUTPUT_DIR not set.")
  stop("ANALYSIS_OUTPUT_DIR not set.", call. = FALSE)
}

raw_params <- commandArgs(trailingOnly = TRUE)
params <- pacta.workflow.utils::parse_raw_params(
  json = raw_params,
  inheritence_search_paths = system.file(
    "extdata", "parameters",
    package = "workflow.pacta"
  ),
  schema_file = system.file(
    "extdata", "schema", "portfolioParameters.json",
    package = "workflow.pacta"
  ),
  raw_schema_file = system.file(
    "extdata", "schema", "rawParameters.json",
    package = "workflow.pacta"
  ),
  force_array = c("portfolio", "files")
)

manifest_info <- workflow.pacta::run_pacta(params)

pacta.workflow.utils::export_manifest(
  input_files = manifest_info[["input_files"]],
  output_files = manifest_info[["output_files"]],
  params = manifest_info[["params"]],
  manifest_path = file.path(Sys.getenv("ANALYSIS_OUTPUT_DIR"), "manifest.json"),
  raw_params = raw_params
)
