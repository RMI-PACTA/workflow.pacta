run_analysis <- function(
  data_dir,
  output_dir,
  equity_market_list,
  scenario_sources_list,
  scenario_geographies_list,
  sector_list,
  has_map
) {

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
  logger::log_formatter(logger::formatter_glue)

  # -------------------------------------------------------------------------

  log_info("Starting PACTA calculations.")

  # quit if there's no relevant PACTA assets --------------------------------

  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")
  if (file.exists(total_portfolio_path)) {
    total_portfolio <- readRDS(total_portfolio_path)
    log_trace(
      "Checking for PACTA relevant data in file: \"{total_portfolio_path}\"."
    )
    pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  } else {
    log_warn("file \"{total_portfolio_path}\" does not exist.")
    warning("File \"total_portfolio.rds\" file does not exist.")
  }


  calc_weights_and_outputs(
    total_portfolio = total_portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = data_dir,
    equity_market_list = equity_market_list,
    scenario_sources_list = scenario_sources_list,
    scenario_geographies_list = scenario_geographies_list,
    sector_list = sector_list,
    has_map = has_map
  )

  calc_weights_and_outputs(
    total_portfolio = total_portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = data_dir,
    equity_market_list = equity_market_list,
    scenario_sources_list = scenario_sources_list,
    scenario_geographies_list = scenario_geographies_list,
    sector_list = sector_list,
    has_map = has_map
  )

  log_info("Finished PACTA calculations.")
}
