run_analysis <- function(
  cfg_path = commandArgs(trailingOnly = TRUE)
) {

  # defaulting to WARN to maintain current (silent) behavior.
  logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
  logger::log_formatter(logger::formatter_glue)

  # -------------------------------------------------------------------------

  log_info("Starting PACTA calculations.")

  log_trace("Determining configuration file path")
  if (length(cfg_path) == 0L || cfg_path == "") {
    log_warn("No configuration file specified, using default")
    cfg_path <- file.path("input_dir", "default_config.json")
  }
  log_debug("Loading configuration from file: \"{cfg_path}\".")
  cfg <- jsonlite::fromJSON(cfg_path)

  # quit if there's no relevant PACTA assets --------------------------------

  total_portfolio_path <- file.path(cfg[["output_dir"]], "total_portfolio.rds")
  if (file.exists(total_portfolio_path)) {
    total_portfolio <- readRDS(total_portfolio_path)
    log_trace(
      "Checking for PACTA relevant data in file: \"{total_portfolio_path}\"."
    )
    pacta.portfolio.utils::quit_if_no_pacta_relevant_data(total_portfolio)
  } else {
    log_warn("file \"{total_portfolio_path}\" does not exist.")
    warning("File \"total_portfolio.rds\" file does not exist.")
  }


  # Equity ------------------------------------------------------------------

  calc_weights_and_outputs(
    total_portfolio = total_portfolio,
    portfolio_type = "Equity",
    cfg = cfg
  )

  # Bonds -------------------------------------------------------------------

  log_info("Starting bonds calculations.")
  port_raw_all_cb <- pacta.portfolio.allocate::create_portfolio_subset(
    portfolio = total_portfolio,
    portfolio_type = "Bonds"
  )

  if (inherits(port_raw_all_cb, "data.frame") && nrow(port_raw_all_cb) > 0L) {
    log_info("Bonds portfolio has data. Beginning bonds calculations.")
    map_cb <- NA
    company_all_cb <- NA
    port_all_cb <- NA

    log_debug("Calculating bonds portfolio weights.")
    port_cb <- pacta.portfolio.allocate::calculate_weights(
      portfolio = port_raw_all_cb,
      portfolio_type = "Bonds"
    )

    log_debug("Merging ABCD data from database into bonds portfolio.")
    port_cb <- pacta.portfolio.allocate::merge_abcd_from_db(
      portfolio = port_cb,
      portfolio_type = "Bonds",
      db_dir = cfg[["data_dir"]],
      equity_market_list = cfg[["equity_market_list"]],
      scenario_sources_list = cfg[["scenario_sources_list"]],
      scenario_geographies_list = cfg[["scenario_geographies_list"]],
      sector_list = cfg[["sector_list"]],
      id_col = "credit_parent_ar_company_id"
    )

    # Portfolio weight methodology
    log_info("Calculating bonds portfolio weight methodology.")
    log_debug("Calculating bonds portfolio weight allocation.")
    port_pw_cb <- pacta.portfolio.allocate::port_weight_allocation(port_cb)

    log_debug(
      "Aggregating companies for bonds portfolio weight calculation."
    )
    company_pw_cb <- pacta.portfolio.allocate::aggregate_company(port_pw_cb)

    log_debug(
      "Aggregating portfolio for bonds portfolio weight calculation."
    )
    port_pw_cb <- pacta.portfolio.allocate::aggregate_portfolio(company_pw_cb)

    # Create combined outputs
    log_debug("Creating combined bonds company outputs.")
    company_all_cb <- company_pw_cb

    log_debug("Creating combined bonds portfolio outputs.")
    port_all_cb <- port_pw_cb

    if (cfg[["has_map"]] && pacta.portfolio.utils::data_check(company_all_cb)) {
      log_debug("Creating bonds map outputs.")
      abcd_raw_cb <- pacta.portfolio.allocate::get_abcd_raw("Bonds")
      log_debug("Merging geography data into bonds map outputs.")
      map_cb <- pacta.portfolio.allocate::merge_in_geography(
        portfolio = company_all_cb,
        ald_raw = abcd_raw_cb
      )
      log_trace("Removing abcd_raw_cb object from memory.")
      rm(abcd_raw_cb)
      log_debug("Aggregating bonds map data.")
      map_cb <- pacta.portfolio.allocate::aggregate_map_data(map_cb)
    }

    # Technology Share Calculation
    if (nrow(port_all_cb) > 0L) {
      log_debug("Calculating bonds portfolio technology share.")
      port_all_cb <- pacta.portfolio.allocate::calculate_technology_share(
        df = port_all_cb
      )
    }

    if (nrow(company_all_cb) > 0L) {
      log_debug("Calculating bonds company technology share.")
      company_all_cb <- pacta.portfolio.allocate::calculate_technology_share(
        df = company_all_cb
      )
    }

    # Scenario alignment calculations
    log_debug("Calculating bonds portfolio scenario alignment.")
    port_all_cb <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = port_all_cb
    )

    log_debug("Calculating bonds company scenario alignment.")
    company_all_cb <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = company_all_cb
    )

    if (pacta.portfolio.utils::data_check(company_all_cb)) {
      log_debug("Saving bonds company results.")
      saveRDS(
        company_all_cb,
        file.path(cfg[["output_dir"]], "Bonds_results_company.rds")
      )
    }

    if (pacta.portfolio.utils::data_check(port_all_cb)) {
      log_debug("Saving bonds portfolio results.")
      saveRDS(
        port_all_cb,
        file.path(cfg[["output_dir"]], "Bonds_results_portfolio.rds")
      )
    }

    if (cfg[["has_map"]] && pacta.portfolio.utils::data_check(map_cb)) {
      log_debug("Saving bonds map results.")
      saveRDS(map_cb, file.path(cfg[["output_dir"]], "Bonds_results_map.rds"))
    }

    log_trace("Removing bonds portfolio objects from memory.")
    rm(port_raw_all_cb)
    rm(port_cb)
    rm(port_pw_cb)
    rm(port_all_cb)
    rm(company_pw_cb)
    rm(company_all_cb)
  } else {
    log_trace("Bonds portfolio has no rows. Skipping bonds calculations.")
  }

  log_info("Finished PACTA calculations.")
}
