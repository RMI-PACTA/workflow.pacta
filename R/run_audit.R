run_audit <- function(
  data_dir,
  portfolio_path,
  output_dir
) {

  log_info("Starting portfolio audit")

  # load necessary input data -------------------------------------------------
  log_info("Loading input data.")

  log_debug("Loading currencies.")
  currencies <- readRDS(file.path(data_dir, "currencies.rds"))

  log_debug("Loading fund data.")
  fund_data <- readRDS(file.path(data_dir, "fund_data.rds"))
  log_debug("Loading fund list data.")
  total_fund_list <- readRDS(
    file.path(data_dir, "total_fund_list.rds")
  )
  log_debug("Loading ISIN to fund table.")
  isin_to_fund_table <- readRDS(
    file.path(data_dir, "isin_to_fund_table.rds")
  )

  log_debug("Loading financial data.")
  fin_data <- readRDS(file.path(data_dir, "financial_data.rds"))

  log_debug("Loading entity info.")
  entity_info <- pacta.portfolio.audit::get_entity_info(dir = data_dir)

  log_debug("Loading Equity ABCD flags.")
  abcd_flags_equity <- readRDS(
    file.path(data_dir, "abcd_flags_equity.rds")
  )
  log_debug("Loading Bonds ABCD flags.")
  abcd_flags_bonds <- readRDS(
    file.path(data_dir, "abcd_flags_bonds.rds")
  )

  log_debug("Loading entity emission intensities.")
  entity_emission_intensities <- readRDS(
    file.path(data_dir, "iss_entity_emission_intensities.rds")
  )
  log_debug("Loading average sector emission intensities.")
  avg_sector_eis <- readRDS(
    file.path(data_dir, "iss_average_sector_emission_intensities.rds")
  )


  # Portfolios --------------------------------------------------------------

  log_info("Reading portfolio from file: \"{portfolio_path}\".")
  portfolio_raw <- pacta.portfolio.import::read_portfolio_csv(
    filepaths = portfolio_path
  )

  log_info("Processing raw portfolio.")
  portfolio <- pacta.portfolio.audit::process_raw_portfolio(
    portfolio_raw = portfolio_raw,
    fin_data = fin_data,
    fund_data = fund_data,
    entity_info = entity_info,
    currencies = currencies,
    total_fund_list = total_fund_list,
    isin_to_fund_table = isin_to_fund_table
  )

  # this is necessary because pacta.portfolio.allocate::add_revenue_split() was
  # removed in #142, but later we realized that it had a sort of hidden
  # behavior where if there is no revenue data it maps the
  # security_mapped_sector column of the portfolio data to financial_sector,
  # which is necessary later
  portfolio[["has_revenue_data"]] <- FALSE
  portfolio[["financial_sector"]] <- portfolio[["security_mapped_sector"]]

  log_debug("Adding ABCD flags to portfolio.")
  portfolio <- pacta.portfolio.audit::create_ald_flag(
    portfolio,
    comp_fin_data = abcd_flags_equity,
    debt_fin_data = abcd_flags_bonds
  )

  log_debug("Adding portfolio flags to portfolio.")
  portfolio_total <- pacta.portfolio.audit::add_portfolio_flags(
    portfolio = portfolio,
    currencies = currencies
  )

  log_debug("Summarizing portfolio.")
  portfolio_overview <- pacta.portfolio.audit::portfolio_summary(
    portfolio_total = portfolio_total
  )

  log_debug("Creating audit file.")
  audit_file <- pacta.portfolio.audit::create_audit_file(
    portfolio_total = portfolio_total,
    has_revenue = FALSE
  )

  log_debug("Calculating financed emissions.")
  emissions_totals <-
    pacta.portfolio.audit::calculate_portfolio_financed_emissions(
      portfolio_total,
      entity_info,
      entity_emission_intensities,
      avg_sector_eis
    )

  # Saving -------------------------------------------------------------------

  log_info("Saving output.")
  log_debug("output directory: \"{output_dir}\".")

  log_debug("Exporting audit information.")
  pacta.portfolio.audit::export_audit_information_data(
    audit_file_ = audit_file,
    portfolio_total_ = portfolio_total,
    folder_path = output_dir
  )

  log_debug("Exporting portfolio total.")
  saveRDS(
    portfolio_total,
    file.path(output_dir, "total_portfolio.rds")
  )
  log_debug("Exporting portfolio overview.")
  saveRDS(
    portfolio_overview,
    file.path(output_dir, "overview_portfolio.rds")
  )
  log_debug("Exporting audit file RDS.")
  saveRDS(audit_file, file.path(output_dir, "audit_file.rds"))
  log_debug("Exporting audit file CSV.")
  readr::write_csv(audit_file, file.path(output_dir, "audit_file.csv"))
  log_debug("Exporting emissions.")
  saveRDS(emissions_totals, file.path(output_dir, "emissions.rds"))

  log_info("Portfolio audit finished.")
}
