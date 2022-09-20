library(tidyverse)
library(rvest)

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



# rest --------------------------------------------------------------------

# build urls to localized overview page
variant <- c(
  "zh-cn", # 大陆简体
  "zh-hk", # 香港繁體
  "zh-mo", # 澳門繁體
  "zh-my", # 大马简体
  "zh-sg", # 新加坡简体
  "zh-tw" # 台灣整體
)


# complete links to variant-specific site (here: simplified)
str_c(base_url, variant[1], df$url, sep = "/")

# apply function to all countries
output <- map(
  str_c(base_url, variant[1], df$url, sep = "/"),
  get_names
)

# get short name from page heading
get_short_name <- function(url) {
  url %>% 
    read_html() %>% 
    html_element("h1#firstHeading") %>% 
    html_text2()
}

short_name <- map(
  str_c(base_url, variant[1], df$url, sep = "/"),
  get_short_name
)

full_name <- map(output, 1)
variant <- map(output, ~.x[-1]) %>% map2(short_name, ~setdiff(.x, .y))

scraped <- tibble(
  short_name = unlist(short_name),
  full_name = unlist(full_name),
  variant
)

scraped %>% unnest_wider(variant)
