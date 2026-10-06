#include <R.h>
#include <Rinternals.h>
#include <R_ext/Rdynload.h>

SEXP r_glpk_version(void);

static const R_CallMethodDef call_methods[] = {
  {"r_glpk_version", (DL_FUNC) &r_glpk_version, 0},
  {NULL, NULL, 0}
};

void R_init_glpsol(DllInfo *dll) {
  R_registerRoutines(dll, NULL, call_methods, NULL, NULL);
  R_useDynamicSymbols(dll, FALSE);
}
