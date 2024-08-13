## save current settings so that we can reset later
threshold <- logger::log_threshold()
appender  <- logger::log_appender()
layout    <- logger::log_layout()
on.exit({
  ## reset logger settings
  logger::log_threshold(threshold)
  logger::log_layout(layout)
  logger::log_appender(appender)
})

logger::log_appender(logger::appender_stdout)
logger::log_threshold(logger::FATAL)
logger::log_layout(logger::layout_simple)

test_that("audit_prechecks works when all files are present", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "currencies.rds",
    "fund_data.rds",
    "total_fund_list.rds",
    "isin_to_fund_table.rds",
    "financial_data.rds",
    "abcd_flags_equity.rds",
    "abcd_flags_bonds.rds",
    "iss_entity_emission_intensities.rds",
    "iss_average_sector_emission_intensities.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  portfolio_dir <- withr::local_tempdir()
  portfolio_files <- "portfolio1.csv"
  write.csv(
    data.frame(a = 1L, b = 2L),
    file.path(portfolio_dir, portfolio_files)
  )

  output_dir <- withr::local_tempdir()

  results <- audit_prechecks(
    pacta_data_dir = pacta_data_dir,
    portfolio_dir = portfolio_dir,
    portfolio_files = portfolio_files,
    output_dir = output_dir
  )
  expect_identical(
    object = results,
    expected = list(
      input_files = c(
        file.path(pacta_data_dir, "currencies.rds"),
        file.path(pacta_data_dir, "fund_data.rds"),
        file.path(pacta_data_dir, "total_fund_list.rds"),
        file.path(pacta_data_dir, "isin_to_fund_table.rds"),
        file.path(pacta_data_dir, "financial_data.rds"),
        file.path(pacta_data_dir, "abcd_flags_equity.rds"),
        file.path(pacta_data_dir, "abcd_flags_bonds.rds"),
        file.path(pacta_data_dir, "iss_entity_emission_intensities.rds"),
        file.path(
          pacta_data_dir, "iss_average_sector_emission_intensities.rds"
        ),
        file.path(portfolio_dir, portfolio_files)
      ),
      output_dir = output_dir
    )
  )
})

test_that("audit_prechecks fails when output_dir not writable", {
  skip_on_os("windows")
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "currencies.rds",
    "fund_data.rds",
    "total_fund_list.rds",
    "isin_to_fund_table.rds",
    "financial_data.rds",
    "abcd_flags_equity.rds",
    "abcd_flags_bonds.rds",
    "iss_entity_emission_intensities.rds",
    "iss_average_sector_emission_intensities.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  portfolio_dir <- withr::local_tempdir()
  portfolio_files <- "portfolio1.csv"
  write.csv(
    data.frame(a = 1L, b = 2L),
    file.path(portfolio_dir, portfolio_files)
  )

  output_dir <- withr::local_tempdir()
  Sys.chmod(output_dir, mode = "000")

  expect_error(
    audit_prechecks(
      pacta_data_dir = pacta_data_dir,
      portfolio_dir = portfolio_dir,
      portfolio_files = portfolio_files,
      output_dir = output_dir
    ),
    regexp = "^IO checks failed.$"
  )
})

test_that("audit_prechecks fails when missing pacta-data files", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "currencies.rds",
    "fund_data.rds",
    "total_fund_list.rds",
    "isin_to_fund_table.rds",
    "financial_data.rds",
    "abcd_flags_equity.rds",
    "abcd_flags_bonds.rds",
    "iss_entity_emission_intensities.rds",
    "iss_average_sector_emission_intensities.rds"
  )
  filenames <- sample(x = filenames, size = 8L, replace = FALSE)
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  portfolio_dir <- withr::local_tempdir()
  portfolio_files <- "portfolio1.csv"
  write.csv(
    data.frame(a = 1L, b = 2L),
    file.path(portfolio_dir, portfolio_files)
  )

  output_dir <- withr::local_tempdir()

  expect_error(
    # supress warnings form pacta.workflow.utils
    suppressWarnings(
      audit_prechecks(
        pacta_data_dir = pacta_data_dir,
        portfolio_dir = portfolio_dir,
        portfolio_files = portfolio_files,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})

test_that("audit_prechecks fails when missing portfolio files", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "currencies.rds",
    "fund_data.rds",
    "total_fund_list.rds",
    "isin_to_fund_table.rds",
    "financial_data.rds",
    "abcd_flags_equity.rds",
    "abcd_flags_bonds.rds",
    "iss_entity_emission_intensities.rds",
    "iss_average_sector_emission_intensities.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  portfolio_dir <- withr::local_tempdir()
  portfolio_files <- c("portfolio1.csv", "portfolio2.csv")
  write.csv(
    data.frame(a = 1L, b = 2L),
    file.path(portfolio_dir, portfolio_files[[1L]])
  )

  output_dir <- withr::local_tempdir()

  expect_error(
    # supress warnings form pacta.workflow.utils
    suppressWarnings(
      audit_prechecks(
        pacta_data_dir = pacta_data_dir,
        portfolio_dir = portfolio_dir,
        portfolio_files = portfolio_files,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})
