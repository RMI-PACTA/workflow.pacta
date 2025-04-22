#' @title Run PACTA
#'
#' @description This function runs the PACTA audit and analysis for a portfolio.
#'
#' @param params List: parameters for analysis. Output of
#' `pacta.workflow.utils::parse_params`. Must contain:
#' \itemize{
#' \item portfolio: List with files key containing the name of the portfolio
#' file.
#' \item analysis: List with keys:
#' \itemize{
#' \item equityMarketList: List of equity markets to analyze.
#' \item scenarioGeographiesList: List of scenario geographies to analyze.
#' \item scenarioSourcesList: List of scenario sources to analyze.
#' \item sectorList: List of sectors to analyze.
#' \item startYear: Start year for analysis.
#' \item timeHorizon: Time horizon for analysis.
#' }
#' }
#' @param run_audit logical: Run the audit process
#' @param run_analysis logical: Run the analysis process
#' @param pacta_data_dir filepath: Directory with "pacta-data"
#' @param output_dir filepath: Directory to save outputs.
#' @param portfolio_dir filepath: Directory with portfolio files
#' @return No return value. Saves outputs to output_dir.
#' @export
run_pacta <- function(
  params,
  run_audit = TRUE,
  run_analysis = TRUE,
  pacta_data_dir = Sys.getenv("PACTA_DATA_DIR"),
  output_dir = Sys.getenv("ANALYSIS_OUTPUT_DIR"),
  portfolio_dir = Sys.getenv("PORTFOLIO_DIR")
) {

  log_debug("Checking configuration.")
  if (is.null(pacta_data_dir) || pacta_data_dir == "") {
    log_error("PACTA_DATA_DIR not set.")
    stop("PACTA_DATA_DIR not set.", call. = FALSE)
  }
  if (is.null(output_dir) || output_dir == "") {
    log_error("ANALYSIS_OUTPUT_DIR not set.")
    stop("ANALYSIS_OUTPUT_DIR not set.", call. = FALSE)
  }
  if (is.null(portfolio_dir) || portfolio_dir == "") {
    log_error("PORTFOLIO_DIR not set.")
    stop("PORTFOLIO_DIR not set.", call. = FALSE)
  }
  log_info("Running PACTA")

  audit_file_path <- file.path(output_dir, "audit_file.rds")

  if (!file.exists(audit_file_path)) {
    log_warn("Audit file not found. Running audit.")
    run_audit <- TRUE
  }

  if (run_audit) {
    audit_prechecks(
      portfolio_files = params[["portfolio"]][["files"]],
      pacta_data_dir = pacta_data_dir,
      portfolio_dir = portfolio_dir,
      output_dir = output_dir
    )
  }

  if (run_analysis) {
    analysis_prechecks(
      pacta_data_dir = pacta_data_dir,
      output_dir = output_dir,
      check_portfolio = FALSE
    )
  }


  if (run_audit) {
    run_audit(
      portfolio_files = params[["portfolio"]][["files"]],
      pacta_data_dir = pacta_data_dir,
      portfolio_dir = portfolio_dir,
      output_dir = output_dir
    )
  }


  if (run_analysis) {
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
  }

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
