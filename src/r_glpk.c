#include <R.h>
#include <Rinternals.h>
#include <glpk.h>

#if GLP_MAJOR_VERSION < 5
#error "glpsol requires GLPK >= 5.0"
#endif

SEXP r_glpk_version(void) {
  return Rf_mkString(glp_version());
}
