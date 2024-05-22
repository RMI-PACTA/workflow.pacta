run_pacta <- function(
  raw_params = commandArgs(trailingOnly = TRUE)
) {
  log_info("Running PACTA")

  # Read Params
  log_trace("Processing input parameters.")
  if (length(raw_params) == 0L || raw_params == "") {
    log_warn("No configuration file specified, using default")
    raw_params <- file.path("input_dir", "default_config.json")
  }
  params <- pacta.workflow.utils:::parse_params(
    json = raw_params
  )

  run_audit(
    data_dir = params[["data_dir"]],
    portfolio_path = params[["portfolio_path"]],
    output_dir = params[["output_dir"]]
  )
  run_analysis(
    data_dir = params[["data_dir"]],
    output_dir = params[["output_dir"]],
    equity_market_list = params[["equity_market_list"]],
    scenario_sources_list = params[["scenario_sources_list"]],
    scenario_geographies_list = params[["scenario_geographies_list"]],
    sector_list = params[["sector_list"]],
    has_map = params[["has_map"]]
  )

  log_info("Exporting Manifest")
  pacta.workflow.utils::export_manifest(
    manifest_path = file.path(params[["output_dir"]], "manifest.json"),
    input_files = c(
      params[["portfolio_path"]],
      list.files(
        params[["data_dir"]],
        full.names = TRUE,
        recursive = TRUE
      )
    ),
    output_files = list.files(
      params[["output_dir"]],
      full.names = TRUE,
      recursive = TRUE
    ),
    params = params,
    raw_params = raw_params
  )

  log_info("PACTA run complete.")
}
