run_pacta <- function(
  cfg_path = commandArgs(trailingOnly = TRUE)
) {
  run_audit(cfg_path)
  run_analysis(cfg_path)
}
