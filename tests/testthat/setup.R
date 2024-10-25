## save current settings so that we can reset later

## Logger Settings
# Set threshold to OFF, and capture previous state
logger_threshold <- logger::log_threshold("OFF")

## Tear down function
withr::defer(
  expr = {
    logger::log_threshold(logger_threshold)
  },
  envir = teardown_env()
)
