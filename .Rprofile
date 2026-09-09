# Skip renv on Posit Cloud: the workshop space has packages preinstalled
# (see install.R), so the project library would only get in the way.
if (!identical(normalizePath(getwd(), winslash = "/", mustWork = FALSE), "/cloud/project")) {
  source("renv/activate.R")
}
