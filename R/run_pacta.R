run_pacta <- function(
  cfg_path = commandArgs(trailingOnly = TRUE)
) {
  log_info("Running PACTA")
  run_audit(cfg_path)
  run_analysis(cfg_path)
  log_info("PACTA run complete.")
}
