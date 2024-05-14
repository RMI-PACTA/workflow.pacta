calc_weights_and_outputs <- function(
  total_portfolio,
  portfolio_type,
  cfg
) {

  # Equity ------------------------------------------------------------------

  log_info("Starting equity calculations.")

  log_debug("Subsetting equity portfolio.")
  port_raw_all_eq <- pacta.portfolio.allocate::create_portfolio_subset(
    portfolio = total_portfolio,
    portfolio_type = "Equity"
  )

  if (inherits(port_raw_all_eq, "data.frame") && nrow(port_raw_all_eq) > 0L) {
    log_info("Equity portfolio has data. Beginning equity calculations.")
    map_eq <- NA
    company_all_eq <- NA
    port_all_eq <- NA

    log_debug("Calculating quity portfolio weights.")
    port_eq <- pacta.portfolio.allocate::calculate_weights(
      portfolio = port_raw_all_eq,
      portfolio_type = "Equity"
    )

    log_debug("Merging ABCD data from database into equity portfolio.")
    port_eq <- pacta.portfolio.allocate::merge_abcd_from_db(
      portfolio = port_eq,
      portfolio_type = "Equity",
      db_dir = cfg[["data_dir"]],
      equity_market_list = cfg[["equity_market_list"]],
      scenario_sources_list = cfg[["scenario_sources_list"]],
      scenario_geographies_list = cfg[["scenario_geographies_list"]],
      sector_list = cfg[["sector_list"]],
      id_col = "id"
    )

    # Portfolio weight methodology
    log_info("Calculating portfolio weight methodology.")
    log_debug("Calculating portfolio weight allocation.")
    port_pw_eq <- pacta.portfolio.allocate::port_weight_allocation(port_eq)

    log_debug("Aggregating companies for portfolio weight calculation.")
    company_pw_eq <- pacta.portfolio.allocate::aggregate_company(port_pw_eq)

    log_debug("Aggregating portfolio for portfolio weight calculation.")
    port_pw_eq <- pacta.portfolio.allocate::aggregate_portfolio(company_pw_eq)

    # Ownership weight methodology
    log_info("Calculating ownership methodology.")
    log_debug("Calculating ownership allocation.")
    port_own_eq <- pacta.portfolio.allocate::ownership_allocation(port_eq)

    log_debug("Aggregating companies for ownership calculation.")
    company_own_eq <- pacta.portfolio.allocate::aggregate_company(port_own_eq)

    log_debug("Aggregating portfolio for ownership calculation.")
    port_own_eq <- pacta.portfolio.allocate::aggregate_portfolio(company_own_eq)

    # Create combined outputs
    log_debug("Creating combined equity company outputs.")
    company_all_eq <- dplyr::bind_rows(company_pw_eq, company_own_eq)

    log_debug("Creating combined equity portfolio outputs.")
    port_all_eq <- dplyr::bind_rows(port_pw_eq, port_own_eq)

    if (cfg[["has_map"]]) {
      log_debug("Creating equity map outputs.")
      abcd_raw_eq <- pacta.portfolio.allocate::get_abcd_raw("Equity")
      log_debug("Merging geography data into equity map outputs.")
      map_eq <- pacta.portfolio.allocate::merge_in_geography(
        portfolio = company_all_eq,
        ald_raw = abcd_raw_eq
      )
      log_trace("Removing abcd_raw_eq object from memory.")
      rm(abcd_raw_eq)

      log_debug("Aggregating equity map data.")
      map_eq <- pacta.portfolio.allocate::aggregate_map_data(map_eq)
    }

    # Technology Share Calculation
    log_debug("Calculating equity portfolio technology share.")
    port_all_eq <- pacta.portfolio.allocate::calculate_technology_share(
      df = port_all_eq
    )

    log_debug("Calculating equity company technology share.")
    company_all_eq <- pacta.portfolio.allocate::calculate_technology_share(
      df = company_all_eq
    )

    # Scenario alignment calculations
    log_debug("Calculating equity portfolio scenario alignment.")
    port_all_eq <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = port_all_eq
    )

    log_debug("Calculating equity company scenario alignment.")
    company_all_eq <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = company_all_eq
    )

    if (pacta.portfolio.utils::data_check(company_all_eq)) {
      log_debug("Saving equity company results.")
      saveRDS(
        company_all_eq,
        file.path(cfg[["output_dir"]], "Equity_results_company.rds")
      )
    }

    if (pacta.portfolio.utils::data_check(port_all_eq)) {
      log_debug("Saving equity portfolio results.")
      saveRDS(
        port_all_eq,
        file.path(cfg[["output_dir"]], "Equity_results_portfolio.rds")
      )
    }

    if (cfg[["has_map"]] && pacta.portfolio.utils::data_check(map_eq)) {
      log_debug("Saving equity map results.")
      saveRDS(
        map_eq,
        file.path(cfg[["output_dir"]], "Equity_results_map.rds")
      )
    }

    log_trace("Removing equity portfolio objects from memory.")
    rm(port_raw_all_eq)
    rm(port_eq)
    rm(port_pw_eq)
    rm(port_own_eq)
    rm(port_all_eq)
    rm(company_pw_eq)
    rm(company_own_eq)
    rm(company_all_eq)
  } else {
    log_trace(
      "Equity portfolio has no rows. Skipping equity calculations."
    )
  }

}
