# Installs the shared library as usual, plus the glpsol executable into
# bin<R_ARCH>/ so that glpsol_path() can find it.
files <- Sys.glob(paste0("*", SHLIB_EXT))
dest <- file.path(R_PACKAGE_DIR, paste0("libs", R_ARCH))
dir.create(dest, recursive = TRUE, showWarnings = FALSE)
file.copy(files, dest, overwrite = TRUE)
if (file.exists("symbols.rds")) {
  file.copy("symbols.rds", dest, overwrite = TRUE)
}

exe <- if (WINDOWS) "glpsol.exe" else "glpsol"
bindir <- file.path(R_PACKAGE_DIR, paste0("bin", R_ARCH))
dir.create(bindir, recursive = TRUE, showWarnings = FALSE)
file.copy(exe, bindir, overwrite = TRUE)
Sys.chmod(file.path(bindir, exe), mode = "0755")
