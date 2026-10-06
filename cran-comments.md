## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

## Bundled GLPK source

The package bundles one file from GLPK 5.0, `src/glpk/glpsol.c` (the
command-line driver), unmodified. It is copyright Free Software Foundation,
Inc. and distributed under GPL-3; the Foundation is listed as a copyright
holder in `Authors@R`, and the origin and licence of the file are recorded in
`inst/COPYRIGHTS`. The package itself is GPL-3, which is compatible.

The GLPK library is not bundled. The package links against the static copy
shipped with Rtools and the CRAN macOS recipes, or the system library on
Linux; `configure` locates it and fails with install instructions if absent.

## Test environments

* Windows 11, R 4.5.3 and R 4.6.1 (local)
* win-builder, R-devel (2026-10-05 r90641)

The win-builder check reported a timeout for <https://www.gnu.org/software/glpk/>
(linked from the README). The URL is the GLPK home page and is correct; the
host was slow to respond at the time of the check.

<!-- Add before submission: R-hub linux + macos -->
