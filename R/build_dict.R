build_dict <- function(regexes) {
  regexes %>% 
    mutate(short_name_en = countrycode::countrycode(iso3c, "iso3c", "country.name.en")) %>% 
    relocate(iso3c, short_name_en, regex)
}