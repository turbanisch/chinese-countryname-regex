# helper function: strip non-Chinese text
clean_chinese_text <- function(s) {
  s %>%
    # remove non-Chinese characters in parentheses (e.g. "(bi4)" for Peru)
    str_remove_all("（[^\\p{script=Han}（）\\p{InCJK_Symbols_and_Punctuation}]+）") %>%
    # remove leading non-Chinese characters (parsing gibberish) but allow full-width parentheses ("刚果（金）")
    str_remove_all("^[^\\p{script=Han}（）\\p{InCJK_Symbols_and_Punctuation}]*") %>%
    .[. != ""] %>%
    # remove footnote artifacts
    str_remove_all("\\[.*\\]")
}

# helper function: collect country name variants (in bold, within first sentence) from a *single* Wikipedia paragraph
try_get_names <- function(url, css_query) {
  page <- url %>% read_html()
  
  first_paragraph_node <- page %>% html_elements(css_query)
  
  first_sentence <- first_paragraph_node %>% 
    html_text2() %>% 
    # delete everything after first dot
    str_remove("。.*$") %>% 
    clean_chinese_text()
  
  names <- first_paragraph_node %>% 
    html_elements("b") %>% 
    html_text2() %>% 
    clean_chinese_text()
  
  unique(names[str_detect(first_sentence, names)])
}

# try to get names from second paragraph if first one is empty
get_names_from_paragraph <- function(url) {
    # try two CSS queries (use second paragraph if first one is empty)
  css_query <- str_c("#mw-content-text > div:nth-child(1) > p:nth-of-type(", 1:2, ")")
  names <- try_get_names(url, css_query[1])
  if (!is_empty(names)) return(names)
  else try_get_names(url, css_query[2])
}

# get short name from page heading
get_short_name <- function(url) {
  url %>% 
    read_html() %>% 
    html_element("h1#firstHeading") %>% 
    html_text2()
}

# combine short name, full name + variants (from paragraph) into tibble
get_names <- function(variant, url_leaf = overview$url) {
  # build full URL
  urls <-
    str_c("https://zh.wikipedia.org", variant, url_leaf, sep = "/")
  
  # get all country names from first (or second) paragraph
  names_from_paragraph <- map(urls, get_names_from_paragraph)
  
  # get short name from country page heading
  short_name <- map(urls, get_short_name)
  
  # extract full names and name variants (other than the short name)
  full_name <- map(names_from_paragraph, 1)
  variant <-
    map(names_from_paragraph, ~ .x[-1]) %>% map2(short_name, ~ setdiff(.x, .y))
  
  # pack into tibble
  tibble(short_name = unlist(short_name),
         full_name = unlist(full_name),
         variant)
}

# scrape all names for each language variant
crawl_country_pages <- function(overview_df) {
  # define language identifiers (used in URL)
  variant <- c("zh-cn",
               "zh-hk",
               "zh-mo",
               "zh-my",
               "zh-sg",
               "zh-tw")
  
  # scrape all names for each language variant
  map_dfr(variant,
          # get names and add English country name (read from right to left)
          ~ overview_df %>% select(short_name_en) %>% bind_cols(get_names(.x)),
          .id = "language") %>%
    arrange(short_name_en, language) %>%
    relocate(short_name_en)
}