mod <- system.file("models", "transp.mod", package = "glpsol")

solve_to <- function(out, ..., model = mod) {
  sol <- file.path(out, "sol.txt"); glp <- file.path(out, "prob.glp")
  res <- glpsol_run(c("-m", model, ..., "-w", sol, "--wglp", glp), echo = FALSE)
  expect_identical(res$status, 0L)
  list(sol = sol, glp = glp)
}

test_that("a basic solution is read with names, statuses and duals", {
  skip_if(mod == "")
  out <- tempfile("glpsol_"); dir.create(out)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  f <- solve_to(out)

  s <- glpsol_read_solution(f$sol, names = f$glp)
  expect_s3_class(s, "glpsol_solution")
  expect_identical(s$kind, "basic")
  expect_identical(s$status, "optimal")
  expect_identical(s$primal_status, "feasible")
  expect_equal(s$objective, 153.675)
  expect_identical(s$problem, "transp")
  expect_identical(s$objective_name, "cost")

  expect_identical(nrow(s$rows), 6L)
  expect_identical(nrow(s$cols), 6L)
  expect_identical(s$rows$name[1:2], c("cost", "supply[Seattle]"))
  expect_identical(s$cols$name[2], "x[Seattle,Chicago]")
  expect_equal(s$cols$primal[s$cols$name == "x[Seattle,Chicago]"], 300)
  expect_equal(s$rows$dual[s$rows$name == "demand[New-York]"], 0.225)
  expect_identical(s$rows$status[s$rows$name == "supply[Seattle]"], "upper")
  expect_true(all(s$cols$status %in% c("basic", "lower")))
  expect_output(print(s), "basic, optimal")
})

test_that("without a names file the indices are still there", {
  skip_if(mod == "")
  out <- tempfile("glpsol_"); dir.create(out)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)
  f <- solve_to(out)

  s <- glpsol_read_solution(f$sol)
  expect_identical(s$cols$index, 1:6)
  expect_true(all(is.na(s$cols$name)))
  expect_true(is.na(s$problem))
})

test_that("interior-point and integer solutions are read", {
  skip_if(mod == "")
  out <- tempfile("glpsol_"); dir.create(out)
  on.exit(unlink(out, recursive = TRUE), add = TRUE)

  f <- solve_to(out, "--interior")
  s <- glpsol_read_solution(f$sol, names = f$glp)
  expect_identical(s$kind, "interior")
  expect_identical(s$status, "optimal")
  expect_true(is.na(s$primal_status))
  expect_equal(s$objective, 153.675, tolerance = 1e-6)
  expect_true(all(is.na(s$cols$status)))
  expect_false(any(is.na(s$cols$dual)))

  # the same model with integer shipments
  mip <- file.path(out, "mip.mod")
  writeLines(sub("var x{i in I, j in J} >= 0;",
                 "var x{i in I, j in J} >= 0, integer;",
                 readLines(mod), fixed = TRUE), mip)
  f <- solve_to(out, model = mip)
  s <- glpsol_read_solution(f$sol, names = f$glp)
  expect_identical(s$kind, "integer")
  expect_identical(s$status, "optimal")
  expect_equal(s$objective, 153.675)
  expect_true(all(is.na(s$cols$dual)))
  expect_true(all(s$cols$primal == round(s$cols$primal)))
})

test_that("malformed files are rejected", {
  expect_error(glpsol_read_solution(tempfile()), "not found")

  bad <- tempfile(fileext = ".txt")
  writeLines(c("Problem:    transp", "Status:     OPTIMAL"), bad)
  expect_error(glpsol_read_solution(bad), "not a GLPK 5.0 solution file")

  writeLines(c("c Problem: x", "s bas 1 1 f f 0", "i 1 b 0 0", "j 1 b 0 0"), bad)
  expect_error(glpsol_read_solution(bad), "truncated")

  writeLines(c("s bas 2 1 f f 0", "i 1 b 0 0", "j 1 b 0 0", "e o f"), bad)
  expect_error(glpsol_read_solution(bad), "declares 2 rows")

  ok <- tempfile(fileext = ".txt")
  writeLines(c("s bas 1 1 f f 0", "i 1 b 0 0", "j 1 b 0 0", "e o f"), ok)
  expect_error(glpsol_read_solution(ok, names = tempfile()), "not found")
  expect_identical(glpsol_read_solution(ok)$status, "optimal")
})
