scrape_overview <- function(url) {
  
  # scrape table nodes
  overview_tables <- url %>%
    read_html() %>%
    html_elements("#mw-content-text > div:nth-child(1) > table:nth-child(7) table") 
  
  # extract sub-tables (3 tables side-by-side) and bind
  overview <- overview_tables%>%
    html_table() %>%
    bind_rows() %>%
    rename(iso3c = X1, name = X2)
  
  # change name of Taiwan
  overview <- overview %>% 
    mutate(name = if_else(iso3c == "TWN", "台湾", name))
  
  # extract urls to country page from table (keep link text for cleaning)
  link_elements <- overview_tables %>% 
    html_elements("a") 
  
  title_href <- tibble(
    name = link_elements %>% html_text2(),
    url = link_elements %>% html_attr("href")
  )
  
  title_href <- title_href %>% 
    mutate(url = str_remove(url, "^/wiki/")) %>% 
    filter(name != "") %>% 
    filter(!str_detect(name, "注"))
  
  # add urls to overview
  overview %>% add_column(url = title_href$url)
}