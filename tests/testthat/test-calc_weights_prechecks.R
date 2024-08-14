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
  data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(data_dir, filename)
    )
  }

  portfolio <- data.frame(a = 1L, b = 2L)

  output_dir <- withr::local_tempdir()

  results_eq <- calc_weights_prechecks(
    total_portfolio = portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = data_dir
  )
  expect_identical(
    object = results_eq,
    expected = list(
      input_files = c(
        file.path(data_dir, "equity_abcd_scenario.rds"),
        file.path(data_dir, "masterdata_ownership_datastore.rds")
      ),
      output_dir = output_dir
    )
  )
  results_cb <- calc_weights_prechecks(
    total_portfolio = portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = data_dir
  )
  expect_identical(
    object = results_cb,
    expected = list(
      input_files = c(
        file.path(data_dir, "bonds_abcd_scenario.rds"),
        file.path(data_dir, "masterdata_debt_datastore.rds")
      ),
      output_dir = output_dir
    )
  )
})

test_that("audit_prechecks works for EQ when EQ files are present", {
  data_dir <- withr::local_tempdir()
  filenames <- c(
    "equity_abcd_scenario.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(data_dir, filename)
    )
  }

  portfolio <- data.frame(a = 1L, b = 2L)

  output_dir <- withr::local_tempdir()

  results_eq <- calc_weights_prechecks(
    total_portfolio = portfolio,
    portfolio_type = "Equity",
    output_dir = output_dir,
    data_dir = data_dir
  )
  expect_identical(
    object = results_eq,
    expected = list(
      input_files = c(
        file.path(data_dir, "equity_abcd_scenario.rds"),
        file.path(data_dir, "masterdata_ownership_datastore.rds")
      ),
      output_dir = output_dir
    )
  )
})

test_that("audit_prechecks works for CB when CB files are present", {
  data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "masterdata_debt_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(data_dir, filename)
    )
  }

  portfolio <- data.frame(a = 1L, b = 2L)

  output_dir <- withr::local_tempdir()

  results_cb <- calc_weights_prechecks(
    total_portfolio = portfolio,
    portfolio_type = "Bonds",
    output_dir = output_dir,
    data_dir = data_dir
  )
  expect_identical(
    object = results_cb,
    expected = list(
      input_files = c(
        file.path(data_dir, "bonds_abcd_scenario.rds"),
        file.path(data_dir, "masterdata_debt_datastore.rds")
      ),
      output_dir = output_dir
    )
  )
})

test_that("audit_prechecks throws error when output_dir not writable", {
  skip_on_os("windows")
  data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(data_dir, filename)
    )
  }

  portfolio <- data.frame(a = 1L, b = 2L)

  output_dir <- withr::local_tempdir()
  Sys.chmod(output_dir, mode = "000")

  for (type in c("Equity", "Bonds")) {
    expect_error(
      calc_weights_prechecks(
        total_portfolio = portfolio,
        portfolio_type = type,
        output_dir = output_dir,
        data_dir = data_dir
      ),
      regexp = "^IO checks failed.$"
    )
  }
})

test_that("audit_prechecks throws error when data files missing", {
  skip_on_os("windows")
  data_dir <- withr::local_tempdir()

  portfolio <- data.frame(a = 1L, b = 2L)

  output_dir <- withr::local_tempdir()

  for (type in c("Equity", "Bonds")) {
    expect_error(
      # suppressWarnings to avoid warning about missing files
      suppressWarnings(
        calc_weights_prechecks(
          total_portfolio = portfolio,
          portfolio_type = type,
          output_dir = output_dir,
          data_dir = data_dir
        )
      ),
      regexp = "^IO checks failed.$"
    )
  }
})

test_that("audit_prechecks errors on empty portfolio", {
  data_dir <- withr::local_tempdir()
  filenames <- c(
    "bonds_abcd_scenario.rds",
    "equity_abcd_scenario.rds",
    "masterdata_debt_datastore.rds",
    "masterdata_ownership_datastore.rds"
  )
  for (filename in filenames) {
    saveRDS(
      1L,
      file.path(data_dir, filename)
    )
  }

  portfolio <- data.frame()

  output_dir <- withr::local_tempdir()

  for (type in c("Equity", "Bonds")) {
    expect_error(
      # suppressWarnings to avoid warning about missing files
      suppressWarnings(
        calc_weights_prechecks(
          total_portfolio = portfolio,
          portfolio_type = type,
          output_dir = output_dir,
          data_dir = data_dir
        )
      ),
      regexp = "^Portfolio has no rows.$"
    )
  }
})
