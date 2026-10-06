# glpsol 0.1.0

* First release.

* Ships GLPK's stand-alone `glpsol` solver, so solving MathProg (GMPL),
  CPLEX LP and MPS models needs no separate GLPK installation on Windows and
  macOS.

* `glpsol_path()` returns the bundled executable; `glpsol_run()` runs it in a
  separate process with an optional live log and a `timeout` that also covers
  model translation and writing the solution, which GLPK's own `--tmlim` does
  not. `glpk_version()` reports the version of the linked library.

* `glpsol_read_solution()` reads the solution file written with `-w` (basic,
  interior-point or integer) into data frames, with row and column names
  attached from the problem file written with `--wglp`.
