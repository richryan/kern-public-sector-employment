# Functions for the analysis

seasonally_adjust <- function(x, date, obs_per_yr, ...) {
  # Check for availability of suggested package seasonal
  if (!requireNamespace("seasonal", quietly = TRUE)) {
    stop(
      "Package \"seasonal\" must be installed to use this function.",
      call. = FALSE
    )
  }
  
  # Check that data are monthly or quarterly
  if ((obs_per_yr != 4) & (obs_per_yr != 12)) {
    stop(
      "The function is designed to handle monthly or quarterly seasonal adjustment."
    )
  }
  
  N <- length(x)
  
  x_indxnon <- which(!is.na(x))
  
  xx <- x[x_indxnon]
  n <- length(xx)
  
  if (n != N) {
    message("   *** Missing values detected.")
  }
  
  date_xx <- date[x_indxnon]
  
  junk <- seasonal::final(seasonal::seas(ts(
    xx,
    start = c(year(min(date_xx)), month(min(date_xx))),
    frequency = obs_per_yr
  ), ...))
  
  x[x_indxnon] <- as.numeric(junk)
  
  return(x)
}

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
    mutate(date = ymd(paste(year, month, "01", sep = "-"))) |> 
    rename(empl_nsa = lvl) |> 
    group_by(own_title) |> 
    mutate(empl = seasonally_adjust(empl_nsa, date, obs_per_yr = 12))
  
  dat_gov_tot <- dat |>
    filter(own_title == "Total Covered") |>
    select(date, empl_nsa) |>
    rename(empl_nsa_tot = empl_nsa)
  
  dat_check <- dat |>
    filter(own_title != "Total Covered") |>
    group_by(date) |>
    summarise(empl_nsa = sum(empl_nsa))
  
  my_caption <- paste("Red: sum(federal gov, state gov, local gov, private)\n",
                      "Black: total covered")
  plt_check_tot <- ggplot(data = dat_gov_tot) +
    geom_line(mapping = aes(x = date, y = empl_nsa_tot)) +
    geom_line(
      data = dat_check,
      mapping = aes(x = date, y = empl_nsa),
      color = "red"
    ) +
    labs(x = "", y = "Employed persons", caption = my_caption)
  
  plt_check_seas <- ggplot(data = dat) +
    geom_line(mapping = aes(x = date, y = empl_nsa, color = own_title)) +
    geom_line(mapping = aes(x = date, y = empl, group = own_title), color = "black", linetype = "dotted")
  
  return(list(dat = dat, plt_check_tot = plt_check_tot, plt_check_seas = plt_check_seas))
}

make_wages <- function(df, dat_pce_deflator) {
  dat_wages <- df |>
    filter(industry_code == "10") |>
    mutate(date = yq(paste0(year, "-", qtr))) |>
    select(date, own_code, own_title, industry_code, avg_wkly_wage) |>
    left_join(dat_pce_deflator, join_by(date)) |>
    mutate(avg_wkly_wage = as.numeric(avg_wkly_wage)) |>
    rename(avg_wkly_wage_nominal_nsa = avg_wkly_wage) |>
    mutate(avg_wkly_wage_nsa = 100 * avg_wkly_wage_nominal_nsa / pce_deflator) |>
    group_by(own_title) |>
    mutate(avg_wkly_wage = seasonally_adjust(avg_wkly_wage_nsa, date, 4))

  plt_check_real <- ggplot(data = dat_wages) +
    geom_line(mapping = aes(x = date, y = avg_wkly_wage_nsa, color = own_title)) +
    geom_line(mapping = aes(x = date, y = avg_wkly_wage_nominal_nsa, color = own_title)) +
    labs(x = "", y = "Average weekly wage")
  
  plt_check_seas <- ggplot(data = dat_wages) +
    geom_line(mapping = aes(x = date, y = avg_wkly_wage_nsa, color = own_title)) +
    geom_line(mapping = aes(x = date, y = avg_wkly_wage, group = own_title), linetype = "dotted", color = "black") +
    labs(x = "", y = "Average weekly wage")  
  
  return(list(dat_wages = dat_wages,
              plt_check_real = plt_check_real,
              plt_check_seas = plt_check_seas))
}

plot_empl <- function(dat_empl, recess_wide) {
  dat <- dat_empl$dat
  
  dat_plt <- filter(dat, own_title != "Total Covered")
  
  chart_begin <- min(dat_plt$date)
  chart_end <- max(dat_plt$date)
  
  dat_lbl_end <- dat_plt |>
    filter(date == max(date)) |>
    mutate(mylabel = paste0(round(empl / 1000, 0)))
  
  dat_lbl <- dat_plt |>
    filter(date == ymd("2003-01-01")) |>
    mutate(mylabel = own_title)
  
  ggplot(data = dat_plt) +
    geom_rect(
      data = filter(recess_wide, begin >= chart_begin, begin <= chart_end),
      mapping = aes(
        xmin = begin,
        xmax = end,
        ymin = -Inf,
        ymax = Inf
      ),
      fill = "blue",
      alpha = 0.2
    ) +
    geom_line(
      mapping = aes(
        x = date,
        y = empl / 1000,
        color = fct_reorder2(own_title, date, empl),
        linetype = fct_reorder2(own_title, date, empl)
      ),
      linewidth = 1.1,
      show.legend = FALSE
    ) +
    geom_text_repel(data = dat_lbl_end,
                    mapping = aes(
                      x = date,
                      y = empl / 1000,
                      label = mylabel
                    )) +
    geom_label_repel(data = dat_lbl,
                     mapping = aes(
                       x = date,
                       y = empl / 1000,
                       label = mylabel
                     )) +
    labs(x = "", y = "Thousands of persons", title = "Employment in Kern County, California") +
    theme_minimal() +
    scale_color_viridis_d(begin = 0.0, end = 0.9)
}

plot_shares <- function(dat_empl, recess_wide) {
  dat_shares <- dat_empl$dat |>
    filter(own_title != "Total Covered") |>
    group_by(date) |>
    mutate(empl_tot = sum(empl)) |>
    arrange(date) |>
    mutate(share = 100 * empl / empl_tot) |>
    ungroup()
  
  dat_shares_lbl <- dat_shares |>
    filter(date == ymd("2003-01-01"))
  
  dat_shares_end <- dat_shares |>
    filter(date == max(date))
  
  ggplot(data = filter(dat_shares, own_title != "Private")) +
    geom_rect(
      data = filter(recess_wide, begin >= chart_begin, begin <= chart_end),
      mapping = aes(
        xmin = begin,
        xmax = end,
        ymin = -Inf,
        ymax = Inf
      ),
      fill = "blue",
      alpha = 0.2
    ) +
    geom_line(
      mapping = aes(
        x = date,
        y = share,
        color = own_title,
        linetype = own_title
      ),
      linewidth = 1.0,
      show.legend = FALSE
    ) +
    geom_text_repel(
      data = filter(dat_shares_end, own_title != "Private"),
      mapping = aes(
        x = date,
        y = share,
        label = paste0(round(share, 1))
      )
    ) +
    geom_label_repel(
      data = filter(dat_shares_lbl, own_title != "Private"),
      mapping = aes(x = date, y = share, label = own_title)
    ) +
    theme_minimal() +
    scale_color_viridis_d(begin = 0.0, end = 0.8) +
    labs(x = "", y = "")
}

# tar_load(recess_wide)
# tar_load(dat_empl)
