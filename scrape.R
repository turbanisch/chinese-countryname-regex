library(tidyverse)
library(rvest)

# urls
variants <- c(
  "zh-cn", # 大陆简体
  "zh-hk", # 香港繁體
  "zh-mo", # 澳門繁體
  "zh-my", # 大马简体
  "zh-sg", # 新加坡简体
  "zh-tw" # 台灣整體
)

urls <- str_c("https://zh.wikipedia.org/", variants, "/世界政區索引")

overview <- urls[1] %>% 
  read_html() %>% 
  html_elements("table") %>% 
  html_table() %>% 
  # subset relevant tables
  .[3:27] %>% 
  bind_rows()

# clean
overview <- overview %>% 
  rename(
    short_name_zh = 国家或地区,
    full_name_zh = 中文全称,
    short_name_en = 英文简称
  ) %>% 
  # convert country codes to NA unless a full set is provided (iso2c-iso3c-iso3n)
  mutate(ISO代码 = if_else(str_detect(ISO代码, "-.*-"), ISO代码, NA_character_)) %>% 
  separate(ISO代码, into = c("iso2c", "iso3c", "iso3n")) %>% 
  # remove footnote artifacts
  mutate(across(.fns = ~str_remove_all(.x, "\\[\\d+\\]"))) %>% 
  # manual replacements
  mutate(
    full_name_zh = if_else(full_name_zh == "阿富汗伊斯兰酋长国（存在争议）", "阿富汗伊斯兰酋长国", full_name_zh),
    short_name_zh = if_else(short_name_zh == "库克群岛（新西兰）", "库克群岛", short_name_zh),
    short_name_zh = if_else(short_name_zh == "纽埃（新西兰）", "纽埃", short_name_zh)
  ) %>% 
  # drop and reorder columns
  select(!c(iso2c, iso3n)) %>% 
  relocate(iso3c, short_name_en)

# find overlap between short and full name
test <- overview %>% select(ends_with("zh")) %>% head(3)
test
str_match(test$short_name_zh, test$full_name_zh)
str_match("阿布哈兹", "阿布哈兹共和国")


overview %>% filter(!str_detect(full_name_zh, short_name_zh))
overview %>% filter(str_detect(full_name_zh, "法"))

# cases
# 1) short name is substring of full name -> keep short name as regex
# 2) common substring is unique 西撒哈拉 + 阿拉伯撒哈拉民主共和国 -> 撒哈拉
# 3) common substring is not unique (X国, e.g. 中国)