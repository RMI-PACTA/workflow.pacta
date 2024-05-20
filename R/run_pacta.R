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
  run_analysis(cfg_path)
  log_info("PACTA run complete.")
}
