prepare_regex <- function(countrynames_wide) {
  # convert everything to simplified and keep unique variants
  variants <- countrynames_wide %>%
    pivot_longer(
      cols = short_name:last_col(),
      names_to = "x",
      values_to = "name"
    ) %>%
    filter(!is.na(name)) %>%
    mutate(name = ropencc::converter(T2S)[name]) %>%
    distinct(iso3c, name)
  
  # add longest common substring as basis for regex
  variants %>%
    group_by(iso3c) %>%
    summarise(variant = list(c(name))) %>%
    mutate(common_string = map_chr(variant , PTXQC::LCSn)) %>%
    unnest_longer(variant) %>%
    # pre-fill regex if one of the variants is a substring of all other variants
    group_by(iso3c) %>%
    mutate(regex = if_else(common_string %in% variant, common_string, "")) %>% 
    ungroup()
}
