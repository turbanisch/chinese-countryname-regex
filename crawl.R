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

# define function to collect names (in bold) from first paragraph on Wikipedia country page
get_names <- function(url) {
  
  output <- url %>% 
    read_html() %>% 
    html_elements("#mw-content-text > div:nth-child(1) > p:nth-of-type(1) > b") %>% 
    html_text2()
  
  if (is_empty(output)) {
  # if a page has an empty first paragraph, try the second one
    output <- url %>% 
      read_html() %>% 
      html_elements("#mw-content-text > div:nth-child(1) > p:nth-of-type(2) > b") %>% 
      html_text2()
  }
  
  if (str_detect(output[1], "^\\.mw-parser-output")) {
    # if parser gibberish is included, extract Chinese characters and concatenate
    output[1] <- output[1] %>% str_extract_all("\\p{script=Han}+") %>% unlist() %>% str_c(collapse = "")
  }
  
  return(output)
}

# apply function to all countries
output <- map(
  str_c(base_url, variant[1], df$url, sep = "/"),
  get_names
)