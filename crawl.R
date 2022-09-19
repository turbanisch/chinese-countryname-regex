library(tidyverse)
library(rvest)

# urls
variant <- c(
  "zh-cn", # 大陆简体
  "zh-hk", # 香港繁體
  "zh-mo", # 澳門繁體
  "zh-my", # 大马简体
  "zh-sg", # 新加坡简体
  "zh-tw" # 台灣整體
)

base_url <- "https://zh.wikipedia.org"

urls <- str_c(base_url, variant, "世界政區索引", sep = "/")

tables <- urls[1] %>% 
  read_html() %>% 
  html_elements("table") %>% 
  # subset relevant tables
  .[3:27] 

country_names <- tables %>% 
  html_elements("td:nth-child(1) > a") %>% 
  html_text2()

country_links <- tables %>% 
  html_elements("td:nth-child(1) > a") %>% 
  html_attr("href") %>% 
  str_remove("^/wiki/")

df <- tibble(
  country = country_names,
  url = country_links 
) %>% 
  filter(country != "")

# complete links to variant-specific site (here: simplified)
str_c(base_url, variant[1], df$url, sep = "/")

# apply function to all countries
output <- map(
  str_c(base_url, variant[1], df$url, sep = "/"),
  get_names
)

get_official_name <- function(url) {
  url %>% 
    read_html() %>% 
    html_elements(".fn") %>% 
    html_text2() %>% 
    # select only first element
    .[1] %>% 
    clean_chinese_text()
  
}

# apply function to all countries
output_official <- map(
  str_c(base_url, variant[1], df$url, sep = "/"),
  get_official_name
)

output_official_clean <- map(
  output_official,
  ~ .x %>% 
    .[1] %>% 
    str_extract("\\p{script=Han}+")
)
