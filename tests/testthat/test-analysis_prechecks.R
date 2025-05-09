test_that("audit_prechecks works when all files are present", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  output_dir <- withr::local_tempdir()
  portfolio <- data.frame(
    asset_type = "Equity",
    has_asset_level_data = TRUE,
    stringsAsFactors = FALSE
  )
  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")
  saveRDS(
    object = portfolio,
    file = total_portfolio_path
  )

  expect_no_error(
    analysis_prechecks(
      total_portfolio_path = total_portfolio_path,
      pacta_data_dir = pacta_data_dir,
      output_dir = output_dir
    )
  )
})

test_that("audit_prechecks fails when total_portfolio.rds missing", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  output_dir <- withr::local_tempdir()
  portfolio <- data.frame(
    asset_type = "Equity",
    has_asset_level_data = TRUE,
    stringsAsFactors = FALSE
  )
  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")

  expect_error(
    # suppressWarnings is used to avoid printing the warning from check_io
    suppressWarnings(
      analysis_prechecks(
        total_portfolio_path = total_portfolio_path,
        pacta_data_dir = pacta_data_dir,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})

test_that("analysis_prechecks passes port missing, check_portfolio is FALSE", {
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  output_dir <- withr::local_tempdir()

  results <- analysis_prechecks(
    total_portfolio_path = NULL,
    pacta_data_dir = pacta_data_dir,
    output_dir = output_dir,
    check_portfolio = FALSE
  )
  expect_identical(
    object = results,
    expected = list(
      input_files = c(
        file.path(pacta_data_dir, "equity_abcd_scenario.rds"),
        file.path(pacta_data_dir, "masterdata_ownership_datastore.rds"),
        file.path(pacta_data_dir, "bonds_abcd_scenario.rds"),
        file.path(pacta_data_dir, "masterdata_debt_datastore.rds")
      ),
      output_dir = output_dir
    )
  )

})

test_that("audit_prechecks fails when output_dir not writable", {
  skip_on_os("windows")
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  output_dir <- withr::local_tempdir()
  portfolio <- data.frame(
    asset_type = "Equity",
    has_asset_level_data = TRUE,
    stringsAsFactors = FALSE
  )
  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")
  Sys.chmod(output_dir, mode = "000")

  expect_error(
    # suppressWarnings is used to avoid printing the warning from check_io
    suppressWarnings(
      analysis_prechecks(
        total_portfolio_path = total_portfolio_path,
        pacta_data_dir = pacta_data_dir,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})

test_that("audit_prechecks fails when data files missing", {
  skip_on_os("windows")
  pacta_data_dir <- withr::local_tempdir()

  output_dir <- withr::local_tempdir()
  portfolio <- data.frame(
    asset_type = "Equity",
    has_asset_level_data = TRUE,
    stringsAsFactors = FALSE
  )
  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")

  expect_error(
    # suppressWarnings is used to avoid printing the warning from check_io
    suppressWarnings(
      analysis_prechecks(
        total_portfolio_path = total_portfolio_path,
        pacta_data_dir = pacta_data_dir,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})

test_that("audit_prechecks fails when no pacta-relevant data", {
  skip_on_os("windows")
  pacta_data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(pacta_data_dir, filename)
    )
  }

  output_dir <- withr::local_tempdir()
  portfolio <- data.frame(
    asset_type = "Equity",
    has_asset_level_data = FALSE,
    stringsAsFactors = FALSE
  )
  total_portfolio_path <- file.path(output_dir, "total_portfolio.rds")

  expect_error(
    # suppressWarnings is used to avoid printing the warning from check_io
    suppressWarnings(
      analysis_prechecks(
        total_portfolio_path = total_portfolio_path,
        pacta_data_dir = pacta_data_dir,
        output_dir = output_dir
      )
    ),
    regexp = "^IO checks failed.$"
  )
})
