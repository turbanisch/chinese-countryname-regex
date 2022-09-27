library(tidyverse)
library(rvest)
library(ropencc)
library(PTXQC)
library(fuzzyjoin)

walk(fs::dir_ls("R/"), source)

# scrape country name variants --------------------------------------------

# scrape country overview page (using the simplified (PRC) version)
# alternative permalink: https://zh.wikipedia.org/w/index.php?title=世界政區索引&oldid=73732739
overview <- scrape_overview("https://zh.wikipedia.org/zh-cn/ISO_3166-1三位字母代码")
write_csv(overview, "data/overview.csv")

# crawl country pages (**takes a long time**)
countrynames <- crawl_country_pages(overview)

countrynames_wide <- countrynames %>% 
  unnest_wider(variant, names_sep = "_") %>% 
  repair_countrynames()

write_csv(countrynames_wide, "data/countrynames.csv")


# load regexes and define test set ----------------------------------------

# find regex test set (= unique variants in simplified Chinese)
variants_simplified <- find_unique_simplified_variants(countrynames_wide)
write_csv(variants_simplified, "data/variants_simplified.csv")

# load existing regexes
regexes <- read_csv("data-raw/regexes.csv", col_types = cols(.default = col_character()))

# test regex --------------------------------------------------------------

# 1. there is only a single regular expression for each country
regexes %>% count(iso3c) %>% filter(n > 1) %>% nrow()

# 2. every regex has at least one simplified variant to test on
regexes %>% anti_join(variants_simplified, by = "iso3c") %>% nrow()

# 3. every relevant variant in simplified Chinese has at least one regex match
variants_simplified %>% 
  regex_anti_join(regexes, by = c("name" = "regex")) %>% 
  nrow()

# 4. there are no false regex matches (i.e., each variant is matched by exactly one regex because of 2.)
variants_simplified %>% 
  regex_left_join(regexes, by = c("name" = "regex")) %>% 
  filter(iso3c.x != iso3c.y) %>% 
  nrow()


# prepare table to find regexes from scratch ------------------------------

# if regex need to be updated (e.g., in case of greater coverage), use this
# otherwise modify data-raw/regexes.csv and run tests iteratively

regex_suggestions <- prepare_regex(variants_simplified, old_regex = regexes)
write_csv(regex_suggestions, "data/regex_suggestions.csv")

