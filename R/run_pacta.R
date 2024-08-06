run_pacta <- function(
  params,
  pacta_data_dir = Sys.getenv("PACTA_DATA_DIR"),
  output_dir = Sys.getenv("ANALYSIS_OUTPUT_DIR"),
  portfolio_dir = Sys.getenv("PORTFOLIO_DIR")
) {

  log_debug("Checking configuration.")
  if (is.null(pacta_data_dir) || pacta_data_dir == "") {
    log_error("PACTA_DATA_DIR not set.")
    stop("PACTA_DATA_DIR not set.")
  }
  if (is.null(output_dir) || output_dir == "") {
    log_error("ANALYSIS_OUTPUT_DIR not set.")
    stop("ANALYSIS_OUTPUT_DIR not set.")
  }
  if (is.null(portfolio_dir) || portfolio_dir == "") {
    log_error("PORTFOLIO_DIR not set.")
    stop("PORTFOLIO_DIR not set.")
  }
  log_info("Running PACTA")

  run_audit(
    portfolio_files = params[["portfolio"]][["files"]],
    pacta_data_dir = pacta_data_dir,
    portfolio_dir = portfolio_dir,
    output_dir = output_dir
  )
  run_analysis(
    pacta_data_dir = pacta_data_dir,
    output_dir = output_dir,
    equity_market_list = params[["analysis"]][["equityMarketList"]],
    scenario_sources_list = params[["analysis"]][["scenarioSourcesList"]],
    scenario_geographies_list =
      params[["analysis"]][["scenarioGeographiesList"]],
    sector_list = params[["analysis"]][["sectorList"]],
    start_year = params[["analysis"]][["startYear"]],
    time_horizon = params[["analysis"]][["timeHorizon"]]
  )

  log_info("PACTA run complete.")
  return(
    list(
      input_files = c(
        file.path(portfolio_dir, params[["portfolio"]][["files"]]),
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
      params = params
    )
  )
}
