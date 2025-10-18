# Functions for the analysis

make_public_sector_empl <- function(dat_qcew_kern) {
  # The main dataset
  dat <- dat_qcew_kern |>
    # Total, all industries
    filter(industry_code == "10") |>
    mutate(date = yq(paste0(year, "-", qtr))) |>
    select(date,
           own_code,
           own_title,
           industry_code,
           matches("^month[123]_emplvl$")) |>
    pivot_longer(cols = ends_with("emplvl"),
                 values_to = "lvl",
                 names_to = "series") |>
    mutate(
      mnth = as.integer(str_sub(series, 6, 6)),
      year = year(date),
      quarter = quarter(date),
      month = 3 * (quarter - 1) + mnth,
      lvl = as.numeric(lvl)
    ) |>
    select(-date) |>
    mutate(date = ymd(paste(year, month, "01", sep = "-")))
  
  dat_gov_tot <- dat |>
    filter(own_title == "Total Covered") |>
    select(date, lvl) |>
    rename(lvl_tot = lvl)
  
  dat_check <- dat |>
    filter(own_title != "Total Covered") |>
    group_by(date) |>
    summarise(lvl = sum(lvl))
  
  my_caption <- paste("Red: sum(federal gov, state gov, local gov, private)\n",
                      "Black: total covered")
  plt_check <- ggplot(data = dat_gov_tot) +
    geom_line(mapping = aes(x = date, y = lvl_tot)) +
    geom_line(
      data = dat_check,
      mapping = aes(x = date, y = lvl),
      color = "red"
    ) +
    labs(x = "", y = "Employed persons", caption = my_caption)
  
  return(list(dat = dat, plt_check = plt_check))
}

tar_load(dat_qcew_kern)
df <- dat_qcew_kern
  dat_wages <- df |> 
    filter(industry_code == "10") |> 
    mutate(date = yq(paste0(year, "-", qtr))) |> 
    select(date, own_code, own_title, industry_code, avg_wkly_wage) |> 
    mutate(avg_wkly_wage = as.numeric(avg_wkly_wage)) |> 
    rename(avg_wkly_wage_nominal = avg_wkly_wage)

make_wages <- function(df) {
  dat_wages <- df |> 
    filter(industry_code == "10") |> 
    mutate(date = yq(paste0(year, "-", qtr))) |> 
    select(date, own_code, own_title, industry_code, avg_wkly_wage) |> 
    mutate(lvl = as.numeric(avg_wkly_wage)) 
}

# Working -----------------------------------------------------------------
