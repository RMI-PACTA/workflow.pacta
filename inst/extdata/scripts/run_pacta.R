logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
workflow.pacta:::run_pacta(commandArgs(trailingOnly = TRUE))
