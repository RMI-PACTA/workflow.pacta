logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))
params <- pacta.workflow.utils::parse_raw_params(
  json = commandArgs(trailingOnly = TRUE),
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
workflow.pacta:::run_pacta(commandArgs(trailingOnly = TRUE))
