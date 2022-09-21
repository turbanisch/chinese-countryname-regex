scrape_overview <- function(url) {
  
  # scrape table nodes
  overview_tables <- url %>%
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
  overview %>%
    # convert country codes to NA unless a full set is provided (iso2c-iso3c-iso3n)
    mutate(ISO代码 = if_else(str_detect(ISO代码, "-.*-"), ISO代码, NA_character_)) %>%
    separate(ISO代码, into = c("iso2c", "iso3c", "iso3n")) %>%
    # drop columns
    select(short_name_en = 英文简称, iso3c) %>%
    add_column(url = country_urls)
}