read_and_clean_regex <- function(path) {
  read_csv(path, col_types = cols(.default = col_character())) %>%
    select(iso3c, regex) %>%
    # first row of each country contains regex
    group_by(iso3c) %>%
    filter(row_number() == 1L) %>%
    ungroup()
}