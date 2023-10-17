suppressPackageStartupMessages({
  library(pacta.portfolio.utils)
  library(pacta.portfolio.import)
  library(pacta.portfolio.audit)
  library(dplyr)
  library(readr)
  library(jsonlite)
})


# -------------------------------------------------------------------------

cfg_path <- commandArgs(trailingOnly = TRUE)
if (length(cfg_path) == 0 || cfg_path == "") { cfg_path <- "input_dir/default_config.json" }
cfg <- fromJSON(cfg_path)


# load necessary input data ----------------------------------------------------

currencies <- readRDS(file.path(cfg$data_dir, "currencies.rds"))

fund_data <- readRDS(file.path(cfg$data_dir, "fund_data.rds"))
total_fund_list <- readRDS(file.path(cfg$data_dir, "total_fund_list.rds"))
isin_to_fund_table <- readRDS(file.path(cfg$data_dir, "isin_to_fund_table.rds"))

fin_data <- readRDS(file.path(cfg$data_dir, "financial_data.rds"))

entity_info <- get_entity_info(dir = cfg$data_dir)

abcd_flags_equity <- readRDS(file.path(cfg$data_dir, "abcd_flags_equity.rds"))
abcd_flags_bonds <- readRDS(file.path(cfg$data_dir, "abcd_flags_bonds.rds"))

entity_emission_intensities <- readRDS(file.path(cfg$data_dir, "iss_entity_emission_intensities.rds"))
average_sector_emission_intensities <- readRDS(file.path(cfg$data_dir, "iss_average_sector_emission_intensities.rds"))


# Portfolios -------------------------------------------------------------------

portfolio_raw <- read_portfolio_csv(cfg$portfolio_path)

portfolio <- process_raw_portfolio(
  portfolio_raw = portfolio_raw,
  fin_data = fin_data,
  fund_data = fund_data,
  entity_info = entity_info,
  currencies = currencies,
  total_fund_list = total_fund_list,
  isin_to_fund_table = isin_to_fund_table
)

# FIXME: this is necessary because pacta.portfolio.allocate::add_revenue_split()
#  was removed in #142, but later we realized that it had a sort of hidden
#  behavior where if there is no revenue data it maps the security_mapped_sector
#  column of the portfolio data to financial_sector, which is necessary later
portfolio <-
  portfolio %>%
  mutate(
    has_revenue_data = FALSE,
    financial_sector = .data$security_mapped_sector
  )

portfolio <- create_ald_flag(portfolio, comp_fin_data = abcd_flags_equity, debt_fin_data = abcd_flags_bonds)

portfolio_total <- add_portfolio_flags(portfolio)

portfolio_overview <- portfolio_summary(portfolio_total)

audit_file <- create_audit_file(portfolio_total, has_revenue = FALSE)

emissions_totals <- calculate_portfolio_financed_emissions(
  portfolio_total,
  entity_info,
  entity_emission_intensities,
  average_sector_emission_intensities
)


# Saving -----------------------------------------------------------------------

export_audit_information_data(
  audit_file_ = audit_file,
  portfolio_total_ = portfolio_total,
  folder_path = cfg$output_dir
)

saveRDS(portfolio_total, file.path(cfg$output_dir, "total_portfolio.rds"))
saveRDS(portfolio_overview, file.path(cfg$output_dir, "overview_portfolio.rds"))
saveRDS(audit_file, file.path(cfg$output_dir, "audit_file.rds"))
write_csv(audit_file, file.path(cfg$output_dir, "audit_file.csv"))
saveRDS(emissions_totals, file.path(cfg$output_dir, "emissions.rds"))
