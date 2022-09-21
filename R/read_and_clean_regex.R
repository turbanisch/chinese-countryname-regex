read_and_clean_regex <- function(path) {
  read_csv(path, col_types = cols(.default = col_character())) %>%
    select(short_name_en, regex) %>%
    # first row of each country contains regex
    group_by(short_name_en) %>%
    filter(row_number() == 1L) %>%
    ungroup()
}