logger::log_threshold(Sys.getenv("LOG_LEVEL", "INFO"))
workflow.pacta:::run_pacta(commandArgs(trailingOnly = TRUE))
