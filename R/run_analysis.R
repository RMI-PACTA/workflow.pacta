suppressPackageStartupMessages({
  library(pacta.portfolio.utils)
  library(pacta.portfolio.allocate)
  library(dplyr)
  library(jsonlite)
})

# defaulting to WARN to maintain current (silent) behavior.
logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
logger::log_formatter(logger::formatter_glue)

# ------------------------------------------------------------------------------

logger::log_info("Starting PACTA calculations.")

logger::log_trace("Determining configuration file path")
cfg_path <- commandArgs(trailingOnly = TRUE)
if (length(cfg_path) == 0 || cfg_path == "") {
  logger::log_warn("No configuration file specified, using default")
  cfg_path <- "input_dir/default_config.json"
}
logger::log_debug("Loading configuration from file: \"{cfg_path}\".")
cfg <- fromJSON(cfg_path)

# quit if there's no relevant PACTA assets -------------------------------------

total_portfolio_path <- file.path(cfg$output_dir, "total_portfolio.rds")
if (file.exists(total_portfolio_path)) {
  total_portfolio <- readRDS(total_portfolio_path)
  logger::log_trace("Checking for PACTA relevant data in file: \"{total_portfolio_path}\".")
  quit_if_no_pacta_relevant_data(total_portfolio)
} else {
  logger::log_warn("file \"{total_portfolio_path}\" does not exist.")
  warning("This is weird... the `total_portfolio.rds` file does not exist in the `30_Processed_inputs` directory.")
}


# Equity -----------------------------------------------------------------------

logger::log_info("Starting equity calculations.")

logger::log_debug("Subsetting equity portfolio.")
port_raw_all_eq <- create_portfolio_subset(total_portfolio, "Equity")

if (inherits(port_raw_all_eq, "data.frame") && nrow(port_raw_all_eq) > 0) {
  logger::log_info("Equity portfolio has data. Beginning equity calculations.")
  map_eq <- NA
  company_all_eq <- NA
  port_all_eq <- NA

  logger::log_debug("Calculating quity portfolio weights.")
  port_eq <- calculate_weights(port_raw_all_eq, "Equity")

  logger::log_debug("Merging ABCD data from database into equity portfolio.")
  port_eq <- merge_abcd_from_db(
    portfolio = port_eq,
    portfolio_type= "Equity",
    db_dir = cfg$data_dir,
    equity_market_list = cfg$equity_market_list,
    scenario_sources_list = cfg$scenario_sources_list,
    scenario_geographies_list = cfg$scenario_geographies_list,
    sector_list = cfg$sector_list,
    id_col = "id"
  )

  # Portfolio weight methodology
  logger::log_info("Calculating portfolio weight methodology.")
  logger::log_debug("Calculating portfolio weight allocation.")
  port_pw_eq <- port_weight_allocation(port_eq)

  logger::log_debug("Aggregating companies for portfolio weight calculation.")
  company_pw_eq <- aggregate_company(port_pw_eq)

  logger::log_debug("Aggregating portfolio for portfolio weight calculation.")
  port_pw_eq <- aggregate_portfolio(company_pw_eq)

  # Ownership weight methodology
  logger::log_info("Calculating ownership methodology.")
  logger::log_debug("Calculating ownership allocation.")
  port_own_eq <- ownership_allocation(port_eq)

  logger::log_debug("Aggregating companies for ownership calculation.")
  company_own_eq <- aggregate_company(port_own_eq)

  logger::log_debug("Aggregating portfolio for ownership calculation.")
  port_own_eq <- aggregate_portfolio(company_own_eq)

  # Create combined outputs
  logger::log_debug("Creating combined equity company outputs.")
  company_all_eq <- bind_rows(company_pw_eq, company_own_eq)

  logger::log_debug("Creating combined equity portfolio outputs.")
  port_all_eq <- bind_rows(port_pw_eq, port_own_eq)

  if (cfg$has_map) {
    logger::log_debug("Creating equity map outputs.")
    abcd_raw_eq <- get_abcd_raw("Equity")
    logger::log_debug("Merging geography data into equity map outputs.")
    map_eq <- merge_in_geography(company_all_eq, abcd_raw_eq)
    logger::log_trace("Removing abcd_raw_eq object from memory.")
    rm(abcd_raw_eq)

    logger::log_debug("Aggregating equity map data.")
    map_eq <- aggregate_map_data(map_eq)
  }

  # Technology Share Calculation
  logger::log_debug("Calculating equity portfolio technology share.")
  port_all_eq <- calculate_technology_share(port_all_eq)

  logger::log_debug("Calculating equity company technology share.")
  company_all_eq <- calculate_technology_share(company_all_eq)

  # Scenario alignment calculations
  logger::log_debug("Calculating equity portfolio scenario alignment.")
  port_all_eq <- calculate_scenario_alignment(port_all_eq)

  logger::log_debug("Calculating equity company scenario alignment.")
  company_all_eq <- calculate_scenario_alignment(company_all_eq)

  if (data_check(company_all_eq)) {
    logger::log_debug("Saving equity company results.")
    saveRDS(company_all_eq, file.path(cfg$output_dir, "Equity_results_company.rds"))
  }

  if (data_check(port_all_eq)) {
    logger::log_debug("Saving equity portfolio results.")
    saveRDS(port_all_eq, file.path(cfg$output_dir, "Equity_results_portfolio.rds"))
  }

  if (cfg$has_map) {
    if (data_check(map_eq)) {
      logger::log_debug("Saving equity map results.")
      saveRDS(map_eq, file.path(cfg$output_dir, "Equity_results_map.rds"))
    }
  }

  logger::log_trace("Removing equity portfolio objects from memory.")
  rm(port_raw_all_eq)
  rm(port_eq)
  rm(port_pw_eq)
  rm(port_own_eq)
  rm(port_all_eq)
  rm(company_pw_eq)
  rm(company_own_eq)
  rm(company_all_eq)
} else {
  logger::log_trace(
    "Equity portfolio has no rows. Skipping equity calculations."
  )
}

# Bonds ------------------------------------------------------------------------

logger::log_info("Starting bonds calculations.")
port_raw_all_cb <- create_portfolio_subset(total_portfolio, "Bonds")

if (inherits(port_raw_all_cb, "data.frame") && nrow(port_raw_all_cb) > 0) {
  logger::log_info("Bonds portfolio has data. Beginning bonds calculations.")
  map_cb <- NA
  company_all_cb <- NA
  port_all_cb <- NA

  logger::log_debug("Calculating bonds portfolio weights.")
  port_cb <- calculate_weights(port_raw_all_cb, "Bonds")

  logger::log_debug("Merging ABCD data from database into bonds portfolio.")
  port_cb <- merge_abcd_from_db(
    portfolio = port_cb,
    portfolio_type = "Bonds",
    db_dir = cfg$data_dir,
    equity_market_list = cfg$equity_market_list,
    scenario_sources_list = cfg$scenario_sources_list,
    scenario_geographies_list = cfg$scenario_geographies_list,
    sector_list = cfg$sector_list,
    id_col = "credit_parent_ar_company_id"
  )

  # Portfolio weight methodology
  logger::log_info("Calculating bonds portfolio weight methodology.")
  logger::log_debug("Calculating bonds portfolio weight allocation.")
  port_pw_cb <- port_weight_allocation(port_cb)

  logger::log_debug(
    "Aggregating companies for bonds portfolio weight calculation."
  )
  company_pw_cb <- aggregate_company(port_pw_cb)

  logger::log_debug(
    "Aggregating portfolio for bonds portfolio weight calculation."
  )
  port_pw_cb <- aggregate_portfolio(company_pw_cb)

  # Create combined outputs
  logger::log_debug("Creating combined bonds company outputs.")
  company_all_cb <- company_pw_cb

  logger::log_debug("Creating combined bonds portfolio outputs.")
  port_all_cb <- port_pw_cb

  if (cfg$has_map) {
    if (data_check(company_all_cb)) {
      logger::log_debug("Creating bonds map outputs.")
      abcd_raw_cb <- get_abcd_raw("Bonds")
      logger::log_debug("Merging geography data into bonds map outputs.")
      map_cb <- merge_in_geography(company_all_cb, abcd_raw_cb)
      logger::log_trace("Removing abcd_raw_cb object from memory.")
      rm(abcd_raw_cb)

      logger::log_debug("Aggregating bonds map data.")
      map_cb <- aggregate_map_data(map_cb)
    }
  }

  # Technology Share Calculation
  if (nrow(port_all_cb) > 0) {
    logger::log_debug("Calculating bonds portfolio technology share.")
    port_all_cb <- calculate_technology_share(port_all_cb)
  }

  if (nrow(company_all_cb) > 0) {
    logger::log_debug("Calculating bonds company technology share.")
    company_all_cb <- calculate_technology_share(company_all_cb)
  }

  # Scenario alignment calculations
  logger::log_debug("Calculating bonds portfolio scenario alignment.")
  port_all_cb <- calculate_scenario_alignment(port_all_cb)

  logger::log_debug("Calculating bonds company scenario alignment.")
  company_all_cb <- calculate_scenario_alignment(company_all_cb)

  if (data_check(company_all_cb)) {
    logger::log_debug("Saving bonds company results.")
    saveRDS(company_all_cb, file.path(cfg$output_dir, "Bonds_results_company.rds"))
  }

  if (data_check(port_all_cb)) {
    logger::log_debug("Saving bonds portfolio results.")
    saveRDS(port_all_cb, file.path(cfg$output_dir, "Bonds_results_portfolio.rds"))
  }
  
  if (cfg$has_map) {
    if (data_check(map_cb)) {
      logger::log_debug("Saving bonds map results.")
      saveRDS(map_cb, file.path(cfg$output_dir, "Bonds_results_map.rds"))
    }
  }

  logger::log_trace("Removing bonds portfolio objects from memory.")
  rm(port_raw_all_cb)
  rm(port_cb)
  rm(port_pw_cb)
  rm(port_all_cb)
  rm(company_pw_cb)
  rm(company_all_cb)
} else {
  logger::log_trace("Bonds portfolio has no rows. Skipping bonds calculations.")
}

logger::log_info("Finished PACTA calculations.")
