#' Read a glpsol solution file
#'
#' Reads the plain-text solution that `glpsol` writes with `-w` (basic,
#' interior-point or integer, whichever the run produced) into data frames.
#' That file identifies rows and columns by index only; pass the problem file
#' written by `--wglp` in the same run to attach their names.
#'
#' @param file Path to the solution file written by `glpsol -w`.
#' @param names Optional path to the problem file written by `glpsol --wglp`
#'   in the same run. Its `n i`/`n j` lines give the row and column names.
#'
#' @return A list of class `"glpsol_solution"` with
#'   * `kind`: `"basic"`, `"interior"` or `"integer"`,
#'   * `status`: `"optimal"`, `"feasible"`, `"infeasible"`, `"no feasible"`
#'     or `"undefined"`,
#'   * `primal_status`, `dual_status`: the two parts of a basic solution's
#'     status (`NA` for the other kinds),
#'   * `objective`: the objective value,
#'   * `problem`, `objective_name`: names from the problem file, if given,
#'   * `rows`, `cols`: data frames with `index`, `name`, `status`, `primal`
#'     and `dual`. `status` is the basis status (`"basic"`, `"lower"`,
#'     `"upper"`, `"free"`, `"fixed"`) and is `NA` for non-basic solution
#'     kinds; `dual` is `NA` for integer solutions.
#' @seealso [glpsol_run()]
#' @export
#' @examples
#' mod <- system.file("models", "transp.mod", package = "glpsol")
#' out <- tempfile("glpsol-"); dir.create(out)
#' sol <- file.path(out, "transp.txt")
#' glp <- file.path(out, "transp.glp")
#'
#' glpsol_run(c("-m", mod, "-w", sol, "--wglp", glp), echo = FALSE)
#' s <- glpsol_read_solution(sol, names = glp)
#' s$status
#' s$objective
#' s$cols[, c("name", "primal", "dual")]
#'
#' unlink(out, recursive = TRUE)
glpsol_read_solution <- function(file, names = NULL) {
  stopifnot(is.character(file), length(file) == 1L)
  if (!file.exists(file)) stop("solution file not found: ", file, call. = FALSE)
  lines <- readLines(file, warn = FALSE)
  lines <- lines[nzchar(lines) & !startsWith(lines, "c")]
  if (length(lines) == 0L || !startsWith(lines[[1L]], "s ")) {
    stop("'", file, "' is not a GLPK 5.0 solution file (expected an 's' line)",
         call. = FALSE)
  }
  if (lines[[length(lines)]] != "e o f") {
    stop("'", file, "' is truncated: no 'e o f' line", call. = FALSE)
  }
  body <- lines[-c(1L, length(lines))]

  s <- strsplit(lines[[1L]], "[[:space:]]+")[[1L]]
  kind <- switch(s[[2L]], bas = "basic", ipt = "interior", mip = "integer",
                 stop("unknown solution kind '", s[[2L]], "' in ", file,
                      call. = FALSE))
  m <- as.integer(s[[3L]]); n <- as.integer(s[[4L]])

  # row/column records: "i <k> ..." then "j <k> ..."
  rec <- utils::read.table(text = body, header = FALSE, colClasses = "character",
                           strip.white = TRUE, quote = "", comment.char = "")
  is_row <- rec[[1L]] == "i"
  if (sum(is_row) != m || sum(!is_row) != n) {
    stop("'", file, "' declares ", m, " rows and ", n, " columns but holds ",
         sum(is_row), " and ", sum(!is_row), call. = FALSE)
  }
  as_df <- function(r) {
    out <- data.frame(index = as.integer(r[[2L]]), name = NA_character_,
                      status = NA_character_, primal = NA_real_,
                      dual = NA_real_, stringsAsFactors = FALSE)
    if (kind == "basic") {
      out$status <- unname(.basis_status[r[[3L]]])
      out$primal <- as.numeric(r[[4L]]); out$dual <- as.numeric(r[[5L]])
    } else if (kind == "interior") {
      out$primal <- as.numeric(r[[3L]]); out$dual <- as.numeric(r[[4L]])
    } else {
      out$primal <- as.numeric(r[[3L]])
    }
    out[order(out$index), , drop = FALSE]
  }
  rows <- as_df(rec[is_row, , drop = FALSE])
  cols <- as_df(rec[!is_row, , drop = FALSE])
  rownames(rows) <- rownames(cols) <- NULL

  if (kind == "basic") {
    pstat <- unname(.sol_status[s[[5L]]]); dstat <- unname(.sol_status[s[[6L]]])
    status <- if (pstat == "feasible" && dstat == "feasible") "optimal" else pstat
    objective <- as.numeric(s[[7L]])
  } else {
    pstat <- dstat <- NA_character_
    status <- unname(.sol_status[s[[5L]]])
    objective <- as.numeric(s[[6L]])
  }

  problem <- objective_name <- NA_character_
  if (!is.null(names)) {
    nm <- .read_glp_names(names)
    problem <- nm$problem; objective_name <- nm$objective
    rows$name <- unname(nm$rows[as.character(rows$index)])
    cols$name <- unname(nm$cols[as.character(cols$index)])
  }

  structure(list(kind = kind, status = status, primal_status = pstat,
                 dual_status = dstat, objective = objective,
                 problem = problem, objective_name = objective_name,
                 rows = rows, cols = cols),
            class = "glpsol_solution")
}

# letters used by glp_write_sol / glp_write_ipt / glp_write_mip
.sol_status <- c(o = "optimal", f = "feasible", i = "infeasible",
                 n = "no feasible", u = "undefined")
.basis_status <- c(b = "basic", l = "lower", u = "upper", f = "free", s = "fixed")

# names from a GLPK-format problem file (glpsol --wglp): "n i <k> <name>",
# "n j <k> <name>", "n p <problem>", "n z <objective>"
.read_glp_names <- function(file) {
  if (!file.exists(file)) stop("problem file not found: ", file, call. = FALSE)
  lines <- readLines(file, warn = FALSE)
  nl <- lines[startsWith(lines, "n ")]
  m <- regmatches(nl, regexec("^n ([ijpz]) ([^ ]+)(?: (.*))?$", nl, perl = TRUE))
  m <- m[lengths(m) > 0L]
  kind <- vapply(m, `[[`, "", 2L)
  a <- vapply(m, `[[`, "", 3L)
  b <- vapply(m, `[[`, "", 4L)
  pick <- function(k) stats::setNames(b[kind == k], a[kind == k])
  list(problem = if (any(kind == "p")) a[kind == "p"][[1L]] else NA_character_,
       objective = if (any(kind == "z")) a[kind == "z"][[1L]] else NA_character_,
       rows = pick("i"), cols = pick("j"))
}

#' @export
print.glpsol_solution <- function(x, ...) {
  cat("<glpsol_solution> ", x$kind, ", ", x$status, "\n", sep = "")
  if (!is.na(x$problem)) cat("problem:   ", x$problem, "\n")
  cat("objective: ", format(x$objective), "\n")
  cat("rows:      ", nrow(x$rows), "\ncols:      ", nrow(x$cols), "\n")
  invisible(x)
}
