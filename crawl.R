library(tidyverse)
library(rvest)
library(tmcn)
library(PTXQC)

walk(fs::dir_ls("R/"), source)


# scrape overview page ----------------------------------------------------

# from simplified version
overview_url <- "https://zh.wikipedia.org/zh-cn/世界政區索引"

# scrape table nodes
overview_tables <- overview_url %>% 
  read_html() %>% 
  html_elements("table") %>% 
  # subset relevant tables
  .[3:27] 

# extract tables from table nodes
overview <- overview_tables %>% 
  html_table() %>% 
  bind_rows()

# extract urls to country page from table
country_urls <- overview_tables %>% 
  html_elements("td:nth-child(1) > a") %>% 
  html_attr("href") %>% 
  str_remove("^/wiki/") %>% 
  # remove links to images
  .[!str_detect(., "^File")]

# keep only English country name and ISO code, add URL
overview <- overview %>% 
  # convert country codes to NA unless a full set is provided (iso2c-iso3c-iso3n)
  mutate(ISO代码 = if_else(str_detect(ISO代码, "-.*-"), ISO代码, NA_character_)) %>% 
  separate(ISO代码, into = c("iso2c", "iso3c", "iso3n")) %>% 
  # drop columns
  select(short_name_en = 英文简称, iso3c) %>% 
  add_column(url = country_urls)
  
overview


# scrape country pages ----------------------------------------------------


# build urls to localized overview page
variant <- c(
  "大陆简体" = "zh-cn",
  "香港繁體" = "zh-hk",
  "澳門繁體" = "zh-mo",
  "大马简体" = "zh-my",
  "新加坡简体" = "zh-sg",
  "台灣整體" = "zh-tw"
)

# scrape all names for each language variant
dict <- map_dfr(variant,
                # get names and add English country name
                ~ overview %>% select(short_name_en) %>% bind_cols(get_names(.x)),
                .id = "language") %>%
  arrange(short_name_en, language) %>% 
  relocate(short_name_en)

dict_wide <- dict %>% unnest_wider(variant, names_sep = "_")

# save
write_rds(dict, "output/dict.rds")
write_rds(dict_wide, "output/dict_wide.rds")


# find regexes ------------------------------------------------------------

# convert everything to simplified and keep unique variants
dict_variants <- dict_wide %>% 
  pivot_longer(cols = short_name:last_col(),
               names_to = "x", 
               values_to = "name") %>% 
  filter(!is.na(name)) %>% 
  mutate(name = toTrad(name, rev = TRUE)) %>% 
  distinct(short_name_en, name)

# find longest common substring
dict_common <- dict_variants %>% 
  group_by(short_name_en) %>% 
  summarise(variant = list(c(name))) %>% 
  mutate(common_string = map_chr(variant ,PTXQC::LCSn)) %>% 
  unnest_longer(variant) %>% 
  # pre-fill regex if one of the variants is a substring of all other variants
  group_by(short_name_en) %>% 
  mutate(regex = if_else(common_string %in% variant, common_string, ""))


write_csv(dict_common, "output/dict_common.csv")


# test regex --------------------------------------------------------------

# load
simplified_regex <- read_csv("data/dict_common_regex_simplified.csv") 

simplified_regex <- simplified_regex %>% 
  select(short_name_en, regex) %>% 
  # first row contains regex
  group_by(short_name_en) %>% 
  filter(row_number() == 1L) %>% 
  ungroup()

# which ones were matched to a wrong country?
dict_variants %>% 
  fuzzyjoin::regex_left_join(simplified_regex, by = c("name" = "regex")) %>% 
  filter(short_name_en.x != short_name_en.y)
# only Taiwan's variant 中国

# which ones could not be matched?
dict_variants %>% 
  fuzzyjoin::regex_anti_join(simplified_regex, by = c("name" = "regex"))
# only the ones that I removed on purpose: outdated names (布鲁克巴, 波斯, 溜山), literal translations (冰封之岛, 奥特亚罗瓦) and ambiguous ones (刚果)