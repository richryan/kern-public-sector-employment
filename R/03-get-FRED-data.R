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

# PCE deflator ------------------------------------------------------------

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
fout <- paste0("dat_", file_prg, "_pce-deflator", "_", today(), ".csv")
write_csv(dat_pce_deflator, file = here("dta", "cln", fout))

# Recession dates ---------------------------------------------------------

recess <- fredrr("USRECM") 
recess_dat <- recess %>% 
  arrange(date) %>% 
  mutate(same = 1 - (value == lag(value))) %>% 
  # Remove first row, an NA, for cumulative sum
  filter(date > min(recess$date)) %>% 
  mutate(era = cumsum(same)) %>% 
  # Filter only recessions
  filter(value == 1)

recess_dat <- recess_dat %>% 
  group_by(era) %>% 
  # Unncessary, but to be sure...
  arrange(date) %>% 
  filter(row_number() == 1 | row_number() == n())

# Now reshape the data wide.
# Each row will contain the start and end dates of a recession.
recess_dat <- recess_dat %>% 
  mutate(junk = row_number()) %>% 
  mutate(begin_end = case_when(
    junk == 1 ~ "begin",
    junk == 2 ~ "end"
  ))

recess_wide <- recess_dat %>%
  ungroup() %>% 
  select(series_id, value, date, era, begin_end) %>% 
  pivot_wider(names_from = begin_end, values_from = date)

fout <- paste0("dat_", file_prg, "_recession-dates", "_", today(), ".csv")
write_csv(recess_wide, file = here("dta", "cln", fout))