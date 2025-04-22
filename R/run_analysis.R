#' @title run_analysis
#'
#' @description This function runs the PACTA analysis for a portfolio.
#'
#' @param pacta_data_dir filepath: Directory with "pacta-data"
#' @param output_dir filepath: Directory to save outputs.
#' @param equity_market_list character vector: List of equity markets to
#' include in analysis.
#' @param scenario_sources_list character vector: List of scenario sources to
#' include in analysis. Note sources must be available in the "pacta-data".
#' @param scenario_geographies_list character vector: List of scenario-defined
#' geographies to include in analysis. Note these geographies must be available
#' in the scenario data.
#' @param sector_list character vector: List of sectors to include in analysis.
#' @param start_year integer: Start year for analysis.
#' @param time_horizon integer: Time horizon after start for analysis (usually
#' 5 years).
#' @return No return value (NULL). Saves outputs to output_dir.
#' @export
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
  return(NULL)
}

analysis_prechecks <- function(
  total_portfolio_path,
  pacta_data_dir,
  output_dir,
  check_portfolio = TRUE
) {
  if (check_portfolio) {
    pacta.workflow.utils::check_io(
      input_files = total_portfolio_path,
      output_dir = output_dir
    )
    total_portfolio <- readRDS(total_portfolio_path)
    log_trace(
      "Checking for PACTA relevant data in file: \"{total_portfolio_path}\"."
    )
    pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  } else {
    log_trace("Skipping portfolio check.")
    total_portfolio <- data.frame()
  }
  equity_prechecks <- calc_weights_prechecks(
    total_portfolio = total_portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = pacta_data_dir,
    check_portfolio = check_portfolio
  )
  bonds_prechecks <- calc_weights_prechecks(
    total_portfolio = total_portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = pacta_data_dir,
    check_portfolio = check_portfolio
  )
  prechecks <- list(
    input_files = unique(
      c(
        equity_prechecks$input_files,
        bonds_prechecks$input_files
      )
    ),
    output_dir = unique(
      c(
        equity_prechecks$output_dir,
        bonds_prechecks$output_dir
      )
    )
  )
  return(prechecks)
}
