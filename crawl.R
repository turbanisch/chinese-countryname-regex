library(tidyverse)
library(rvest)
library(ropencc)
library(PTXQC)

walk(fs::dir_ls("R/"), source)

# scrape and build dict ---------------------------------------------------

# scrape country overview page (using the simplified (PRC) version)
# alternative permalink: https://zh.wikipedia.org/w/index.php?title=世界政區索引&oldid=73732739
overview <- scrape_overview("https://zh.wikipedia.org/zh-cn/世界政區索引")
write_csv(overview, "data/overview.csv")

# crawl country pages (**takes a long time**)
countrynames <- crawl_country_pages(overview)
countrynames_wide <- countrynames %>% unnest_wider(variant, names_sep = "_")
write_csv(countrynames_wide, "data/countrynames.csv")

# find longest common substrings among all variants (converted to simplified) to prepare regexes
countrynames_lcs <- prepare_regex(countrynames_wide)
# write_csv(countrynames_lcs, "data/countrynames_lcs.csv")

# add regexes (manually added based on the longest common substring)
regexes <- read_and_clean_regex("data-raw/countrynames_lcs_regex.csv")

# prepare full conversion table (add iso3c from overview + manually added regexes)
dict <- build_dict(countrynames_wide, overview, regexes)
write_csv(dict, "data/dict.csv")


# test regex --------------------------------------------------------------

# which ones were matched to a wrong country?
countrynames_lcs %>% 
  fuzzyjoin::regex_left_join(regexes, by = c("name" = "regex")) %>% 
  filter(short_name_en.x != short_name_en.y)
# only Taiwan's variant 中国

# which ones could not be matched?
countrynames_lcs %>% 
  fuzzyjoin::regex_anti_join(regexes, by = c("name" = "regex"))
# only the ones that I removed on purpose: outdated names (布鲁克巴, 波斯, 溜山), literal translations (冰封之岛, 奥特亚罗瓦) and ambiguous ones (刚果)



