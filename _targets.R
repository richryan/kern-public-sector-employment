library(targets)

# Load packages for the project
tar_source("R/packages.R")


# Update data -------------------------------------------------------------

# tar_source("R/01-get-QCEW-data.R")
# tar_source("R/02-collect-QCEW-data-kern.R")


# Targets pipeline with fixed data ----------------------------------------

list(
  # Data fixed for the replication ------------------------------------------
  tar_target(file_qcew_kern, here("dta", "cln", "dat_02-collect-QCEW-data-kern.csv"), format = "file"),
  tar_target(file_pce_deflator, here("dta", "cln", "dat_03-get-FRED-data_pce-deflator.csv"), format = "file"),
  tar_target(dat_qcew_kern, read_csv(file_qcew_kern)),
  tar_target(dat_pce_deflator, read_csv(file_pce_deflator))
)



