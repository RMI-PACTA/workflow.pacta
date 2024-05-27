run_pacta <- function(
  raw_params = commandArgs(trailingOnly = TRUE),
  pacta_data_dir = Sys.getenv("PACTA_DATA_DIR"),
  output_dir = Sys.getenv("OUTPUT_DIR"),
  portfolio_dir = Sys.getenv("PORTFOLIO_DIR")
) {

  log_debug("Checking configuration.")
  if (is.null(pacta_data_dir) || pacta_data_dir == "") {
    log_error("PACTA_DATA_DIR not set.")
    stop("PACTA_DATA_DIR not set.")
  }
  if (is.null(output_dir) || output_dir == "") {
    log_error("OUTPUT_DIR not set.")
    stop("OUTPUT_DIR not set.")
  }
  if (is.null(portfolio_dir) || portfolio_dir == "") {
    log_error("PORTFOLIO_DIR not set.")
    stop("PORTFOLIO_DIR not set.")
  }
  log_info("Running PACTA")

  # Read Params
  log_trace("Processing input parameters.")
  if (length(raw_params) == 0L || all(raw_params == "")) {
    log_error("No parameters specified.")
  }

  log_trace("Validating raw input parameters.")
  raw_input_validation_results <- jsonvalidate::json_validate(
    json = raw_params,
    schema = system.file(
      "extdata", "schema", "rawParameters.json",
      package = "workflow.pacta"
    ),
    verbose = TRUE,
    greedy = FALSE,
    engine = "ajv"
  )
  if (raw_input_validation_results) {
    log_trace("Raw input parameters are valid.")
  } else {
    log_error(
      "Invalid raw input parameters. ",
      "Must include \"inherit\" key, or match full schema."
    )
    stop("Invalid raw input parameters.")
  }

  params <- pacta.workflow.utils:::parse_params(
    json = raw_params,
    inheritence_search_paths = system.file(
      "extdata", "parameters",
      package = "workflow.pacta"
    ),
    schema_file = system.file(
      "extdata", "schema", "portfolioParameters_0-0-1.json",
      package = "workflow.pacta"
    )
  )

  run_audit(
    portfolio_files = params[["portfolio_files"]],
    pacta_data_dir = pacta_data_dir,
    portfolio_dir = portfolio_dir,
    output_dir = output_dir
  )
  run_analysis(
    pacta_data_dir = pacta_data_dir,
    output_dir = output_dir,
    equity_market_list = params[["equity_market_list"]],
    scenario_sources_list = params[["scenario_sources_list"]],
    scenario_geographies_list = params[["scenario_geographies_list"]],
    sector_list = params[["sector_list"]],
    start_year = params[["start_year"]],
    time_horizon = params[["time_horizon"]]
  )

  log_info("Exporting Manifest")
  pacta.workflow.utils::export_manifest(
    manifest_path = file.path(output_dir, "manifest.json"),
    input_files = c(
      file.path(portfolio_dir, params[["portfolio_files"]]),
      list.files(
        pacta_data_dir,
        full.names = TRUE,
        recursive = TRUE
      )
    ),
    output_files = list.files(
      output_dir,
      full.names = TRUE,
      recursive = TRUE
    ),
    params = params,
    raw_params = raw_params
  )

  log_info("PACTA run complete.")
}
