#' @keywords internal
"_PACKAGE"

# Supress lintr warnings about functions re-exported from logger
utils::globalVariables(
  c(
    "log_debug",
    "log_error",
    "log_info",
    "log_trace",
    "log_warn"
  )
)

## usethis namespace: start
#' @importFrom logger log_debug
#' @importFrom logger log_error
#' @importFrom logger log_info
#' @importFrom logger log_trace
#' @importFrom logger log_warn
## usethis namespace: end
NULL
