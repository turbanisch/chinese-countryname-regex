build_dict <- function(countrynames_wide, overview, regexes) {
  countrynames_wide %>%
    select(!starts_with("variant")) %>%
    pivot_wider(names_from = language,
                values_from = c(short_name, full_name)) %>%
    # merge iso3c from overview
    left_join(select(overview, iso3c, short_name_en), by = "short_name_en") %>% 
    # merge regexes
    left_join(regexes, by = "short_name_en") %>% 
    relocate(short_name_en, iso3c, regex)
}