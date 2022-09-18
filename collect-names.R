library(dplyr)
library(stringr)

countrycode::codelist %>% 
  select(ends_with(c("zh", "de")))

# see which abbreviations are used to denote Chinese in countrycode's codelist (variants of "zh")
zh_endings <- countrycode::codelist %>% 
  colnames() %>% 
  str_extract("\\.[^.]+$") %>% 
  tibble(language = .) %>% 
  filter(str_detect(language, "zh")) %>% 
  distinct(language) %>% 
  pull(language)

# see which columns there are for Chinese in countrycode's codelist
countrycode::codelist %>% 
  select(ends_with(zh_endings)) %>% 
  filter(un.name.zh == "中国") %>% 
  glimpse()

# observations: 
# un.name is less comprehensive (covers only UN member states)
# 
  

# add country codes
custom_dict <- unique(countrycode::codelist[, c("cldr.short.zh", "country.name.en", "iso3c")])

chinese_to_iso3c <- function(country_name_zh) {
  countrycode::countrycode(
    country_name_zh,
    origin = "cldr.short.zh",
    destination = "iso3c",
    custom_dict = custom_dict,
    custom_match = c(
      "刚果共和国" = "COG",
      "多米尼加" = "DOM",
      "沙特" = "SAU",
      "阿联酋" = "ARE"
    )
  )
}

countrycode::codelist[, c("cldr.name.zh", "country.name.en", "iso3c")]
countrycode::codelist %>% 
  select(
    country.name.en, 
    country.name.en.regex, 
    iso3c, 
    cldr.short.zh, 
    cldr.short.zh_hant,
    cldr.short.zh_hant_hk) %>% 
  filter(cldr.short.zh_hant != cldr.short.zh_hant_hk)

str_detect("阿爾巴尼亞", "尔")
