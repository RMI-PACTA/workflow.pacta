run_pacta <- function(
  cfg_path = commandArgs(trailingOnly = TRUE)
) {
  log_info("Running PACTA")

  # Read Params
  log_trace("Determining configuration file path")
  if (length(cfg_path) == 0L || cfg_path == "") {
    log_warn("No configuration file specified, using default")
    cfg_path <- file.path("input_dir", "default_config.json")
  }
  log_debug("Loading configuration from file: \"{cfg_path}\".")
  cfg <- jsonlite::fromJSON(cfg_path)

  run_audit(
    data_dir = cfg[["data_dir"]],
    portfolio_path = cfg[["portfolio_path"]],
    output_dir = cfg[["output_dir"]]
  )
  run_analysis(
    data_dir = cfg[["data_dir"]],
    output_dir = cfg[["output_dir"]],
    equity_market_list = cfg[["equity_market_list"]],
    scenario_sources_list = cfg[["scenario_sources_list"]],
    scenario_geographies_list = cfg[["scenario_geographies_list"]],
    sector_list = cfg[["sector_list"]],
    has_map = cfg[["has_map"]]
  )
  log_info("PACTA run complete.")
}
