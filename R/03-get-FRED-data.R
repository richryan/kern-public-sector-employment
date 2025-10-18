file_prg <- "03-get-FRED-data"

fred_api_key <- Sys.getenv("FRED_API_KEY")
fredrr <- function(vars, from) {
  if (missing(from)) {
    from <- ymd("1776-07-04")
  }
  dat <- list_rbind(
    map(vars, fredr::fredr, observation_start = from, observation_end = ymd("9999-12-31"))
  ) |> 
    select(-starts_with("realtime_"))
  
  return(dat)
}

# Personal Consumption Expenditures: Chain-type Price Index (PCECTPI)
# Units: Index 2017=100, Seasonally Adjusted
# Frequency: Quarterly
dat_pce_deflator <- fredrr("PCECTPI") |> 
  rename(pce_deflator = value)

# Make the most recent period the base year
date_max <- max(dat_pce_deflator$date)

pce_indx <- dat_pce_deflator |> filter(date == date_max) |> pull(pce_deflator)

dat_pce_deflator <- dat_pce_deflator |> 
  mutate(pce_deflator = 100 * pce_deflator / pce_indx)

# Save series
fout <- paste0("dat_", file_prg, "_pce-deflator.csv")
write_csv(dat_pce_deflator, file = here("dta", "cln", fout))
