library(targets)

# Load packages for the project
tar_source("R/packages.R")

# Set target options:
tar_option_set(
  # Packages that your targets need for their tasks.
  packages = c("seasonal") 
)

# Update data -------------------------------------------------------------

# tar_source("R/01-get-QCEW-data.R")
# tar_source("R/02-collect-QCEW-data-kern.R")
# tar_source("R/03-get-FRED-data.R")

# Targets pipeline with fixed data ----------------------------------------

tar_source("R/04-analysis.R")

list(
  # Data fixed for the replication ------------------------------------------
  tar_target(file_qcew_kern, here("dta", "cln", "dat_02-collect-QCEW-data-kern_2025-10-18.csv"), format = "file"),
  tar_target(file_pce_deflator, here("dta", "cln", "dat_03-get-FRED-data_pce-deflator_2025-10-18.csv"), format = "file"),
  tar_target(file_recess_wide, here("dta", "cln", "dat_03-get-FRED-data_recession-dates_2025-10-18.csv"), format = "file"),
  tar_target(dat_qcew_kern, read_csv(file_qcew_kern)),
  tar_target(dat_pce_deflator, read_csv(file_pce_deflator)),
  tar_target(recess_wide, read_csv(file_recess_wide)),
  # 04-analysis -------------------------------------------------------------
  tar_target(dat_empl, make_public_sector_empl(dat_qcew_kern = dat_qcew_kern)),
  tar_target(dat_wages, make_wages(dat_qcew_kern, dat_pce_deflator)),
  tar_target(plt_empl, plot_empl(dat_empl, recess_wide)),
  tar_target(plt_shares, plot_empl(dat_empl, recess_wide))
)

