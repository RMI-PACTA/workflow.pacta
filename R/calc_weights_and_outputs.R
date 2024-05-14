calc_weights_and_outputs <- function(
  total_portfolio,
  portfolio_type,
  output_dir,
  data_dir,
  equity_market_list,
  scenario_sources_list,
  scenario_geographies_list,
  sector_list,
  has_map
) {

  log_info("Starting {portfolio_type} calculations.")

  log_debug("Subsetting {portfolio_type} portfolio.")
  port_raw_all <- pacta.portfolio.allocate::create_portfolio_subset(
    portfolio = total_portfolio,
    portfolio_type = portfolio_type
  )

  if (pacta.portfolio.utils::data_check(port_raw_all)) {
    log_info(
      "{portfolio_type} portfolio has data. ",
      "Beginning {portfolio_type} calculations."
    )

    log_debug("Calculating {portfolio_type} portfolio weights.")
    port <- pacta.portfolio.allocate::calculate_weights(
      portfolio = port_raw_all,
      portfolio_type = portfolio_type
    )

    log_debug(
      "Merging ABCD data from database into {portfolio_type} portfolio."
    )
    if (portfolio_type == "Bonds") {
      id_col <- "credit_parent_ar_company_id"
    } else {
      id_col <- "id"
    }
    id_col <- "credit_parent_ar_company_id"
    port <- pacta.portfolio.allocate::merge_abcd_from_db(
      portfolio = port,
      portfolio_type = portfolio_type,
      db_dir = data_dir,
      equity_market_list = equity_market_list,
      scenario_sources_list = scenario_sources_list,
      scenario_geographies_list = scenario_geographies_list,
      sector_list = sector_list,
      id_col = id_col
    )

    # Portfolio weight methodology
    log_info("Calculating portfolio weight methodology.")
    log_debug("Calculating portfolio weight allocation.")
    port_pw <- pacta.portfolio.allocate::port_weight_allocation(port)

    log_debug("Aggregating companies for portfolio weight calculation.")
    company_pw <- pacta.portfolio.allocate::aggregate_company(port_pw)

    log_debug("Aggregating portfolio for portfolio weight calculation.")
    port_pw <- pacta.portfolio.allocate::aggregate_portfolio(company_pw)

    if (portfolio_type == "Bonds") {
      log_info("Ownership weight calculation not defined for Bonds. Skipping.")
      port_own <- NULL
      company_own <- NULL
    } else {
      # Ownership weight methodology
      log_info("Calculating ownership methodology.")
      log_debug("Calculating ownership allocation.")
      port_own <- pacta.portfolio.allocate::ownership_allocation(port)

      log_debug("Aggregating companies for ownership calculation.")
      company_own <- pacta.portfolio.allocate::aggregate_company(port_own)

      log_debug("Aggregating portfolio for ownership calculation.")
      port_own <- pacta.portfolio.allocate::aggregate_portfolio(company_own)
    }

    # Create combined outputs
    log_debug("Creating combined {portfolio_type} company outputs.")
    company_all <- dplyr::bind_rows(company_pw, company_own)

    log_debug("Creating combined {portfolio_type} portfolio outputs.")
    port_all <- dplyr::bind_rows(port_pw, port_own)

    if (has_map && pacta.portfolio.utils::data_check(company_all)) {
      log_debug("Creating {portfolio_type} map outputs.")
      abcd_raw <- pacta.portfolio.allocate::get_abcd_raw(portfolio_type)
      log_debug("Merging geography data into {portfolio_type} map outputs.")
      map <- pacta.portfolio.allocate::merge_in_geography(
        portfolio = company_all,
        ald_raw = abcd_raw
      )
      log_trace("Removing abcd_raw object from memory.")
      rm(abcd_raw)

      log_debug("Aggregating {portfolio_type} map data.")
      map <- pacta.portfolio.allocate::aggregate_map_data(map)
    }

    # Technology Share Calculation
    if (nrow(port_all) > 0L) {
      log_debug("Calculating {portfolio_type} portfolio technology share.")
      port_all <- pacta.portfolio.allocate::calculate_technology_share(
        df = port_all
      )
    }

    if (nrow(company_all) > 0L) {
      log_debug("Calculating {portfolio_type} company technology share.")
      company_all <- pacta.portfolio.allocate::calculate_technology_share(
        df = company_all
      )
    }

    # Scenario alignment calculations
    log_debug("Calculating {portfolio_type} portfolio scenario alignment.")
    port_all <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = port_all
    )

    log_debug("Calculating {portfolio_type} company scenario alignment.")
    company_all <- pacta.portfolio.allocate::calculate_scenario_alignment(
      df = company_all
    )

    results_company_filename <- file.path(
      output_dir,
      paste0(portfolio_type, "_results_company.rds")
    )
    if (pacta.portfolio.utils::data_check(company_all)) {
      log_debug("Saving {portfolio_type} company results.")
      saveRDS(
        company_all,
        results_company_filename
      )
    }

    results_portfolio_filename <- file.path(
      output_dir,
      paste0(portfolio_type, "_results_portfolio.rds")
    )
    if (pacta.portfolio.utils::data_check(port_all)) {
      log_debug("Saving {portfolio_type} portfolio results.")
      saveRDS(
        port_all,
        results_portfolio_filename
      )
    }

    if (has_map && pacta.portfolio.utils::data_check(map)) {
      log_debug("Saving {portfolio_type} map results.")
      results_map_filename <- file.path(
        output_dir,
        paste0(portfolio_type, "_results_map.rds")
      )
      saveRDS(
        map,
        results_map_filename
      )
    }

  } else {
    log_trace(
      "{portfolio_type} portfolio has no rows. ",
      "Skipping {portfolio_type} calculations."
    )
  }

}
