test_that("the bundled executable is installed and reports a GLPK version", {
  exe <- glpsol_path()
  expect_true(file.exists(exe))
  expect_match(basename(exe), "^glpsol")

  # the C layer links the same GLPK the executable was built from
  expect_match(glpk_version(), "^[0-9]+[.][0-9]+$")
})

test_that("glpsol_run captures the log and reports status", {
  res <- glpsol_run("--version", echo = FALSE)
  expect_identical(res$status, 0L)
  expect_false(res$timed_out)
  expect_true(any(grepl("GLPK", res$log)))
  # the executable and the linked library must agree
  expect_true(any(grepl(glpk_version(), res$log, fixed = TRUE)))
})

test_that("a MathProg model solves to the known optimum", {
  mod <- system.file("models", "transp.mod", package = "glpsol")
  skip_if(mod == "", "inst/models/transp.mod not installed")

  out <- tempfile("glpsol_"); dir.create(out)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  sol <- file.path(out, "transp.sol")
  res <- glpsol_run(c("-m", mod, "-o", sol), echo = FALSE)

  expect_identical(res$status, 0L)
  expect_true(file.exists(sol))
  expect_true(any(grepl("OPTIMAL LP SOLUTION FOUND", res$log, fixed = TRUE)))

  # transp.mod is GLPK's shipped transportation example; the optimum is
  # 153.675, written in the log in exponential form ("obj = 1.536750000e+02")
  obj <- grep("obj =", res$log, fixed = TRUE, value = TRUE)
  expect_gt(length(obj), 0)
  last <- sub(".*obj =[[:space:]]*", "", obj[length(obj)])
  last <- as.numeric(sub("[[:space:]].*$", "", last))
  expect_equal(last, 153.675, tolerance = 1e-6)
})

test_that("echo = TRUE streams instead of returning the log", {
  # `echo = TRUE` passes stdout = "" to system2(), so the child writes straight
  # to the terminal. That bypasses the connection testthat captures, which is
  # why the stream itself is not asserted here - only that nothing is collected.
  res <- glpsol_run("--version", echo = TRUE)
  expect_identical(res$log, character(0))
  expect_identical(res$status, 0L)

  # ... whereas echo = FALSE collects the same text
  quiet <- glpsol_run("--version", echo = FALSE)
  expect_gt(length(quiet$log), 0)
})

test_that("a timeout is reported rather than thrown", {
  # --help returns immediately, so this only checks the plumbing is wired
  res <- glpsol_run("--help", echo = FALSE, timeout = 30)
  expect_false(res$timed_out)
  expect_type(res$timed_out, "logical")
})

test_that("arguments are validated", {
  expect_error(glpsol_run(args = 1L))
  expect_error(glpsol_run("--help", timeout = "soon"))
  expect_error(glpsol_run("--help", echo = "yes"))
})
