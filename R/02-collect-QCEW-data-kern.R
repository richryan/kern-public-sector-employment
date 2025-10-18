file_prg <- "02-collect-QCEW-data-kern"

# Get relevant files
get_qcew_files <- here("dta", "src", list.files(path = here("dta", "src"), pattern = "^[0-9]{4}.*\\.csv", recursive = TRUE))

# Collect Kern files
kern_files <- get_qcew_files[str_detect(get_qcew_files, "Kern")]


read_in_qcew_files <- function(fin) {
  df <- read_csv(fin,
                 col_types = cols(.default = col_character()))
}

dat_all_list <- map(kern_files, read_in_qcew_files)
dat_all <- list_rbind(dat_all_list)

# Save the dataset
fout <- paste0("dat_", file_prg, "_", today(), ".csv")
write_csv(dat_all, file = here("dta", "cln", fout))
