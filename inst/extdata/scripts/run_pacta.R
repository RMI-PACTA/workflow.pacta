logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))

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
  )
)

manifest_info <- workflow.pacta:::run_pacta(params)

log_info("Exporting Manifest")
pacta.workflow.utils::export_manifest(
  input_files = manifest_info[["input_files"]],
  output_files = manifest_info[["output_files"]],
  params = manifest_info[["params"]],
  manifest_path = file.path(output_dir, "manifest.json"),
  raw_params = raw_params
)
