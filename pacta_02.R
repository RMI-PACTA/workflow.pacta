suppressPackageStartupMessages({
  library(pacta.portfolio.utils)
  library(pacta.portfolio.allocate)
  library(dplyr)
  library(jsonlite)
})


# ------------------------------------------------------------------------------

cfg_path <- commandArgs(trailingOnly = TRUE)
if (length(cfg_path) == 0 || cfg_path == "") { cfg_path <- "input_dir/default_config.json" }
cfg <- fromJSON(cfg_path)


# quit if there's no relevant PACTA assets -------------------------------------

total_portfolio_path <- file.path(cfg$output_dir, "total_portfolio.rds")
if (file.exists(total_portfolio_path)) {
  total_portfolio <- readRDS(total_portfolio_path)
  quit_if_no_pacta_relevant_data(total_portfolio)
} else {
  warning("This is weird... the `total_portfolio.rds` file does not exist in the `30_Processed_inputs` directory.")
}


# Equity -----------------------------------------------------------------------

port_raw_all_eq <- create_portfolio_subset(total_portfolio, "Equity")

if (inherits(port_raw_all_eq, "data.frame") && nrow(port_raw_all_eq) > 0) {
  map_eq <- NA
  company_all_eq <- NA
  port_all_eq <- NA

  port_eq <- calculate_weights(port_raw_all_eq, "Equity")

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
  port_pw_eq <- port_weight_allocation(port_eq)

  company_pw_eq <- aggregate_company(port_pw_eq)

  port_pw_eq <- aggregate_portfolio(company_pw_eq)

  # Ownership weight methodology
  port_own_eq <- ownership_allocation(port_eq)

  company_own_eq <- aggregate_company(port_own_eq)

  port_own_eq <- aggregate_portfolio(company_own_eq)

  # Create combined outputs
  company_all_eq <- bind_rows(company_pw_eq, company_own_eq)

  port_all_eq <- bind_rows(port_pw_eq, port_own_eq)

  if (cfg$has_map) {
    abcd_raw_eq <- get_abcd_raw("Equity")
    map_eq <- merge_in_geography(company_all_eq, abcd_raw_eq)
    rm(abcd_raw_eq)

    map_eq <- aggregate_map_data(map_eq)
  }

  # Technology Share Calculation
  port_all_eq <- calculate_technology_share(port_all_eq)

  company_all_eq <- calculate_technology_share(company_all_eq)

  # Scenario alignment calculations
  port_all_eq <- calculate_scenario_alignment(port_all_eq)

  company_all_eq <- calculate_scenario_alignment(company_all_eq)

  if (data_check(company_all_eq)) {
    saveRDS(company_all_eq, file.path(cfg$output_dir, "Equity_results_company.rds"))
  }

  if (data_check(port_all_eq)) {
    port_all_eq_tdm <- port_all_eq %>%
      filter(scenario_geography == "Global", equity_market == "GlobalMarket")

    tdm_vars <- list(
      t0 = cfg$start_year,
      delta_t1 = 5,
      delta_t2 = 9,
      additional_groups = c(
        "scenario_source",
        "scenario",
        "allocation",
        "equity_market",
        "scenario_geography"
      ),
      scenarios = "IPR FPS 2021"
    )

    if (
      tdm_conditions_met(
        port_all_eq_tdm,
        t0 = tdm_vars$t0,
        delta_t1 = tdm_vars$delta_t1,
        delta_t2 = tdm_vars$delta_t2,
        additional_groups = tdm_vars$additional_groups,
        scenarios = tdm_vars$scenarios,
        project_code = cfg$project_code
      )
    ) {

      equity_tdm <-
        calculate_tdm(
          port_all_eq_tdm,
          t0 = tdm_vars$t0,
          delta_t1 = tdm_vars$delta_t1,
          delta_t2 = tdm_vars$delta_t2,
          additional_groups = tdm_vars$additional_groups,
          scenarios = tdm_vars$scenarios
        )

      saveRDS(equity_tdm, file.path(cfg$output_dir, "Equity_tdm.rds"))

      port_all_eq <- filter(port_all_eq, !scenario %in% tdm_vars$scenarios)
    }

    saveRDS(port_all_eq, file.path(cfg$output_dir, "Equity_results_portfolio.rds"))
  }
  if (cfg$has_map) {
    if (data_check(map_eq)) {
      saveRDS(map_eq, file.path(cfg$output_dir, "Equity_results_map.rds"))
    }
  }

  rm(port_raw_all_eq)
  rm(port_eq)
  rm(port_pw_eq)
  rm(port_own_eq)
  rm(port_all_eq)
  rm(company_pw_eq)
  rm(company_own_eq)
  rm(company_all_eq)
}


# Bonds ------------------------------------------------------------------------

port_raw_all_cb <- create_portfolio_subset(total_portfolio, "Bonds")

if (inherits(port_raw_all_cb, "data.frame") && nrow(port_raw_all_cb) > 0) {
  map_cb <- NA
  company_all_cb <- NA
  port_all_cb <- NA

  port_cb <- calculate_weights(port_raw_all_cb, "Bonds")

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
  port_pw_cb <- port_weight_allocation(port_cb)

  company_pw_cb <- aggregate_company(port_pw_cb)

  port_pw_cb <- aggregate_portfolio(company_pw_cb)

  # Create combined outputs
  company_all_cb <- company_pw_cb

  port_all_cb <- port_pw_cb

  if (cfg$has_map) {
    if (data_check(company_all_cb)) {
      abcd_raw_cb <- get_abcd_raw("Bonds")
      map_cb <- merge_in_geography(company_all_cb, abcd_raw_cb)
      rm(abcd_raw_cb)

      map_cb <- aggregate_map_data(map_cb)
    }
  }

  # Technology Share Calculation
  if (nrow(port_all_cb) > 0) {
    port_all_cb <- calculate_technology_share(port_all_cb)
  }

  if (nrow(company_all_cb) > 0) {
    company_all_cb <- calculate_technology_share(company_all_cb)
  }

  # Scenario alignment calculations
  port_all_cb <- calculate_scenario_alignment(port_all_cb)

  company_all_cb <- calculate_scenario_alignment(company_all_cb)

  if (data_check(company_all_cb)) {
    saveRDS(company_all_cb, file.path(cfg$output_dir, "Bonds_results_company.rds"))
  }
  if (data_check(port_all_cb)) {
    port_all_cb_tdm <- port_all_cb %>%
      filter(scenario_geography == "Global", equity_market == "GlobalMarket")

    tdm_vars <- list(
      t0 = cfg$start_year,
      delta_t1 = 5,
      delta_t2 = 9,
      additional_groups = c(
        "scenario_source",
        "scenario",
        "allocation",
        "equity_market",
        "scenario_geography"
      ),
      scenarios = "IPR FPS 2021"
    )

    if (
      tdm_conditions_met(
        port_all_cb_tdm,
        t0 = tdm_vars$t0,
        delta_t1 = tdm_vars$delta_t1,
        delta_t2 = tdm_vars$delta_t2,
        additional_groups = tdm_vars$additional_groups,
        scenarios = tdm_vars$scenarios,
        project_code = cfg$project_code
      )
    ) {

      bonds_tdm <-
        calculate_tdm(
          port_all_cb_tdm,
          t0 = tdm_vars$t0,
          delta_t1 = tdm_vars$delta_t1,
          delta_t2 = tdm_vars$delta_t2,
          additional_groups = tdm_vars$additional_groups,
          scenarios = tdm_vars$scenarios
        )

      saveRDS(bonds_tdm, file.path(cfg$output_dir, "Bonds_tdm.rds"))

      port_all_cb <- filter(port_all_cb, !scenario %in% tdm_vars$scenarios)
    }

    saveRDS(port_all_cb, file.path(cfg$output_dir, "Bonds_results_portfolio.rds"))
  }
  if (cfg$has_map) {
    if (data_check(map_cb)) {
      saveRDS(map_cb, file.path(cfg$output_dir, "Bonds_results_map.rds"))
    }
  }

  rm(port_raw_all_cb)
  rm(port_cb)
  rm(port_pw_cb)
  rm(port_all_cb)
  rm(company_pw_cb)
  rm(company_all_cb)
}