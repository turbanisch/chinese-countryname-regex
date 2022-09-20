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

# helper function: collect names from a single paragraph
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

# define function to collect country name variants (in bold, within first sentence) from the first Wikipedia paragraph
get_names <- function(url) {
    # try two CSS queries (use second paragraph if first one is empty)
  css_query <- str_c("#mw-content-text > div:nth-child(1) > p:nth-of-type(", 1:2, ")")
  names <- try_get_names(url, css_query[1])
  if (!is_empty(names)) return(names)
  else try_get_names(url, css_query[2])
}