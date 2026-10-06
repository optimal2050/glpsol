#' Path to the bundled glpsol executable
#'
#' The package installs GLPK's stand-alone solver `glpsol` next to its
#' shared library. Use this path wherever a `glpsol` command is expected.
#'
#' @return Normalised path to the executable. An error is raised if it is
#'   missing from the installation.
#' @seealso [glpsol_run()]
#' @export
#' @examples
#' glpsol_path()
glpsol_path <- function() {
  exe <- if (.Platform$OS.type == "windows") "glpsol.exe" else "glpsol"
  root <- system.file(package = "glpsol")
  candidates <- c(
    file.path(root, paste0("bin", Sys.getenv("R_ARCH")), exe),
    file.path(root, "bin", exe),
    file.path(root, "src", exe) # devtools::load_all() from the source tree
  )
  # Under pkgload::load_all() `system.file()` points at `inst/`, while the
  # freshly compiled executable sits in the package's own `src/`.
  if (basename(root) == "inst") {
    candidates <- c(candidates, file.path(dirname(root), "src", exe))
  }
  hit <- candidates[file.exists(candidates)]
  if (length(hit) == 0L) {
    stop("glpsol executable not found in the glpsol installation (",
         root, "); reinstall the package.", call. = FALSE)
  }
  normalizePath(hit[[1L]], winslash = "/")
}

#' Run the bundled glpsol executable
#'
#' Runs `glpsol` as a separate process with the given command-line
#' arguments. A crash or a runaway solve cannot take down the R session, and
#' `timeout` stops it on every platform.
#'
#' @param args Character vector of command-line arguments, as for the
#'   `glpsol` CLI, e.g. `c("-m", "model.mod", "-d", "model.dat", "-o",
#'   "model.sol")`. Each element is quoted for the shell, so file names may
#'   contain spaces.
#' @param wd Working directory for the run; relative paths in `args` are
#'   resolved against it. `NULL` uses the current directory.
#' @param timeout Time limit in seconds for the process; `0` means no limit.
#'   Unlike `--tmlim`, this also covers model translation and output writing.
#' @param echo If `TRUE`, the solver log is printed to the console as it
#'   runs. If `FALSE`, it is captured and returned in `log`.
#'
#' @return Invisibly, a list with
#'   * `status`: exit status, `0` on success,
#'   * `timed_out`: `TRUE` if `timeout` was reached,
#'   * `log`: captured output lines (`character(0)` when `echo = TRUE`).
#' @seealso [glpsol_path()]
#' @export
#' @examples
#' mod <- system.file("models", "transp.mod", package = "glpsol")
#' res <- glpsol_run(c("-m", mod), echo = FALSE)
#' res$status
#' tail(res$log, 3)
glpsol_run <- function(args = "--help", wd = NULL, timeout = 0, echo = TRUE) {
  stopifnot(is.character(args), is.numeric(timeout), length(timeout) == 1L,
            is.logical(echo), length(echo) == 1L)
  exe <- glpsol_path()
  if (!is.null(wd)) {
    old <- setwd(wd)
    on.exit(setwd(old), add = TRUE)
  }
  qtype <- if (.Platform$OS.type == "windows") "cmd" else "sh"
  qargs <- shQuote(args, type = qtype)
  if (echo) {
    status <- suppressWarnings(
      system2(exe, qargs, stdout = "", stderr = "", timeout = timeout)
    )
    log <- character(0)
  } else {
    log <- suppressWarnings(
      system2(exe, qargs, stdout = TRUE, stderr = TRUE, timeout = timeout)
    )
    status <- attr(log, "status")
    if (is.null(status)) status <- 0L
    attributes(log) <- NULL
  }
  # system2() reports a timeout as exit status 124
  timed_out <- timeout > 0 && identical(as.integer(status), 124L)
  invisible(list(status = as.integer(status), timed_out = timed_out,
                 log = log))
}
