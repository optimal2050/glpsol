# glpsol

The stand-alone solver of the GNU Linear Programming Kit (GLPK), distributed
as an R package.

`glpsol` reads [MathProg](https://www.gnu.org/software/glpk/) (GMPL) models
with separate data files, CPLEX LP files and MPS files, solves them with the
simplex, interior-point or branch-and-cut methods, and writes the solution to a
file. This package builds and installs the executable, runs it from R as a
separate process with a time limit and an optional live log, and reads the
solution file back into R.

## Installation

```r
install.packages("glpsol")
```

On Windows and macOS the CRAN binary contains a static copy of GLPK; no other
software needs to be installed or placed on the `PATH`. On Linux the package is
installed from source and requires the GLPK development files:

```sh
sudo apt-get install libglpk-dev      # Debian/Ubuntu
sudo dnf install glpk-devel           # Fedora/RHEL
brew install glpk                     # macOS, source installation only
```

The development version is installed from GitHub under the same requirements:

```r
pak::pak("optimal2050/glpsol")
```

## Usage

```r
library(glpsol)

glpsol_path()    # the bundled executable
glpk_version()   # the version of the GLPK library the package was built against

mod <- system.file("models", "transp.mod", package = "glpsol")
sol <- tempfile(fileext = ".txt")
glp <- tempfile(fileext = ".glp")
res <- glpsol_run(c("-m", mod, "-w", sol, "--wglp", glp), echo = FALSE)

res$status       # 0 when glpsol ran to completion
tail(res$log, 3)

s <- glpsol_read_solution(sol, names = glp)
s$status
s$objective
s$cols[, c("name", "primal", "dual")]
```

`glpsol_run()` accepts the arguments of the `glpsol` command line. With
`echo = TRUE` the solver log is written to the console as it is produced;
`timeout` terminates the run after a given number of seconds on all platforms
and applies to the whole run, including model translation and output.
`glpsol_read_solution()` reads the solution written with `-w` into data frames,
with row and column names taken from the problem file written with `--wglp`.

The vignette, `vignette("glpsol")`, describes the package in more detail.

## Use from other packages

`glpsol_path()` is the integration point. The following function uses the
bundled executable when the package is installed and otherwise falls back to a
copy found on the `PATH`:

```r
find_glpsol <- function() {
  if (requireNamespace("glpsol", quietly = TRUE)) {
    hit <- tryCatch(glpsol::glpsol_path(), error = function(e) NULL)
    if (!is.null(hit) && file.exists(hit)) return(hit)
  }
  Sys.which("glpsol")
}
```

## Relation to other packages

[glpkAPI](https://CRAN.R-project.org/package=glpkAPI), the R binding to the
GLPK C API, was archived from CRAN in March 2026. This package fills the
resulting gap at the command-line level: it provides GLPK through
`install.packages()` and runs MathProg models with separate data files from R.
The solver runs in a separate process and the results are returned through
files; the package does not provide an interface to the C API.

Two alternatives remain for that purpose:

* [Rglpk](https://CRAN.R-project.org/package=Rglpk) links the same library and
  solves a matrix-level LP in-process with `Rglpk_solve_LP()`. It reads a
  single MathProg file but not separate `-d` data files, and writes no
  solution files.
* glpkAPI can still be installed from the
  [CRAN archive](https://CRAN.R-project.org/src/contrib/Archive/glpkAPI/)
  against a system GLPK installation and provides the full API, including
  named rows and columns, sensitivity analysis and callbacks.

## Licence

GPL-3. The package includes the `glpsol` driver source from GLPK 5.0,
copyright Free Software Foundation, Inc.; see `inst/COPYRIGHTS`. GLPK itself
is distributed under GPL-3.
