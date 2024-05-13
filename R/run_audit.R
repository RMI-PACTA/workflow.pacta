suppressPackageStartupMessages({
  library(pacta.portfolio.utils)
  library(pacta.portfolio.import)
  library(pacta.portfolio.audit)
  library(dplyr)
  library(readr)
  library(jsonlite)
})

# defaulting to WARN to maintain current (silent) behavior.
logger::log_threshold(Sys.getenv("LOG_LEVEL", "WARN"))
logger::log_formatter(logger::formatter_glue)

# -------------------------------------------------------------------------

logger::log_info("Starting portfolio audit")

logger::log_trace("Determining configuration file path")
cfg_path <- commandArgs(trailingOnly = TRUE)
if (length(cfg_path) == 0 || cfg_path == "") {
  logger::log_warn("No configuration file specified, using default")
  cfg_path <- "input_dir/default_config.json"
}
logger::log_debug("Loading configuration from file: \"{cfg_path}\".")
cfg <- fromJSON(cfg_path)

# load necessary input data ----------------------------------------------------

logger::log_info("Loading input data.")

logger::log_debug("Loading currencies.")
currencies <- readRDS(file.path(cfg$data_dir, "currencies.rds"))

logger::log_debug("Loading fund data.")
fund_data <- readRDS(file.path(cfg$data_dir, "fund_data.rds"))
logger::log_debug("Loading fund list data.")
total_fund_list <- readRDS(file.path(cfg$data_dir, "total_fund_list.rds"))
logger::log_debug("Loading ISIN to fund table.")
isin_to_fund_table <- readRDS(file.path(cfg$data_dir, "isin_to_fund_table.rds"))

logger::log_debug("Loading financial data.")
fin_data <- readRDS(file.path(cfg$data_dir, "financial_data.rds"))

logger::log_debug("Loading entity info.")
entity_info <- get_entity_info(dir = cfg$data_dir)

logger::log_debug("Loading Equity ABCD flags.")
abcd_flags_equity <- readRDS(file.path(cfg$data_dir, "abcd_flags_equity.rds"))
logger::log_debug("Loading Bonds ABCD flags.")
abcd_flags_bonds <- readRDS(file.path(cfg$data_dir, "abcd_flags_bonds.rds"))

logger::log_debug("Loading entity emission intensities.")
entity_emission_intensities <- readRDS(file.path(cfg$data_dir, "iss_entity_emission_intensities.rds"))
logger::log_debug("Loading average sector emission intensities.")
average_sector_emission_intensities <- readRDS(
  file.path(cfg$data_dir, "iss_average_sector_emission_intensities.rds")
)


# Portfolios -------------------------------------------------------------------

logger::log_info("Reading portfolio from file: \"{cfg$portfolio_path}\".")
portfolio_raw <- read_portfolio_csv(cfg$portfolio_path)

logger::log_info("Processing raw portfolio.")
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

logger::log_debug("Adding ABCD flags to portfolio.")
portfolio <- create_ald_flag(portfolio, comp_fin_data = abcd_flags_equity, debt_fin_data = abcd_flags_bonds)

logger::log_debug("Adding portfolio flags to portfolio.")
portfolio_total <- add_portfolio_flags(portfolio)

logger::log_debug("Summarizing portfolio.")
portfolio_overview <- portfolio_summary(portfolio_total)

logger::log_debug("Creating audit file.")
audit_file <- create_audit_file(portfolio_total, has_revenue = FALSE)

logger::log_debug("Calculating financed emissions.")
emissions_totals <- calculate_portfolio_financed_emissions(
  portfolio_total,
  entity_info,
  entity_emission_intensities,
  average_sector_emission_intensities
)

# Saving -----------------------------------------------------------------------

logger::log_info("Saving output.")
logger::log_debug("output directory: \"{cfg$output_dir}\".")

logger::log_debug("Exporting audit information.")
export_audit_information_data(
  audit_file_ = audit_file,
  portfolio_total_ = portfolio_total,
  folder_path = cfg$output_dir
)

logger::log_debug("Exporting portfolio total.")
saveRDS(portfolio_total, file.path(cfg$output_dir, "total_portfolio.rds"))
logger::log_debug("Exporting portfolio overview.")
saveRDS(portfolio_overview, file.path(cfg$output_dir, "overview_portfolio.rds"))
logger::log_debug("Exporting audit file RDS.")
saveRDS(audit_file, file.path(cfg$output_dir, "audit_file.rds"))
logger::log_debug("Exporting audit file CSV.")
write_csv(audit_file, file.path(cfg$output_dir, "audit_file.csv"))
logger::log_debug("Exporting emissions.")
saveRDS(emissions_totals, file.path(cfg$output_dir, "emissions.rds"))

logger::log_info("Portfolio audit finished.")
