prepare_regex <- function(countrynames_df, old_regex) {
  # add longest common substring, suggest as regex if it matches an entire variant
  variants <- countrynames_df %>%
    group_by(iso3c) %>%
    summarise(variant = list(c(name))) %>%
    mutate(lcs = map_chr(variant , PTXQC::LCSn)) %>%
    unnest_longer(variant) %>%
    # pre-fill regex if one of the variants is a substring of all other variants
    group_by(iso3c) %>%
    mutate(suggestion = if_else(lcs %in% variant, lcs, "")) %>% 
    ungroup()
  
  # merge existing regular expressions
  variants %>% 
    left_join(old_regex, by = "iso3c") %>% 
    rename(old_regex = regex)
}