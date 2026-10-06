#' @keywords internal
#' @useDynLib glpsol, .registration = TRUE
"_PACKAGE"

#' Version of the linked GLPK library
#'
#' @return A character string, e.g. `"5.0"`.
#' @export
#' @examples
#' glpk_version()
glpk_version <- function() {
  .Call(r_glpk_version)
}
