# manually repair bugs from scraping
repair_countrynames <- function(df) {
  df %>%
    # add BES before 群島
    mutate(across(.fns = ~ if_else(
      iso3c == "BES" & .x %in% c("群岛", "群島"),
      str_c("BES", .x),
      .x
    ))) %>%
    # remove 世界最大岛 for Greenland
    mutate(across(.fns = ~ if_else(
      iso3c == "GRL" & .x == "世界最大岛",
      NA_character_,
      .x
    )))
}