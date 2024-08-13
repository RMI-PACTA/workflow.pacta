run_analysis <- function(
  pacta_data_dir,
  output_dir,
  equity_market_list,
  scenario_sources_list,
  scenario_geographies_list,
  sector_list,
  start_year,
  time_horizon
) {

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
  logger::log_formatter(logger::formatter_glue)

  # -------------------------------------------------------------------------

  log_info("Starting PACTA calculations.")

  # quit if there's no relevant PACTA assets --------------------------------

  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")
  analysis_prechecks(
    total_portfolio_path = total_portfolio_path,
    pacta_data_dir = pacta_data_dir,
    output_dir = output_dir
  )
  total_portfolio <- readRDS(total_portfolio_path)


  calc_weights_and_outputs(
    total_portfolio = total_portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = pacta_data_dir,
    equity_market_list = equity_market_list,
    scenario_sources_list = scenario_sources_list,
    scenario_geographies_list = scenario_geographies_list,
    sector_list = sector_list,
    start_year = start_year,
    time_horizon = time_horizon
  )

  calc_weights_and_outputs(
    total_portfolio = total_portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = pacta_data_dir,
    equity_market_list = equity_market_list,
    scenario_sources_list = scenario_sources_list,
    scenario_geographies_list = scenario_geographies_list,
    sector_list = sector_list,
    start_year = start_year,
    time_horizon = time_horizon
  )

  log_info("Finished PACTA calculations.")
}

analysis_prechecks <- function(
  total_portfolio_path,
  pacta_data_dir,
  output_dir
  ) {
  pacta.workflow.utils::check_io(
    input_files = total_portfolio_path,
    output_dir = output_dir
  )
  total_portfolio <- readRDS(total_portfolio_path)
  log_trace(
    "Checking for PACTA relevant data in file: \"{total_portfolio_path}\"."
  )
  pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  calc_weights_prechecks(
    total_portfolio = total_portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = pacta_data_dir
  )
  calc_weights_prechecks(
    total_portfolio = total_portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = pacta_data_dir
  )
}
