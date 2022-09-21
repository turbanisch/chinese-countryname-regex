# strip non-Chinese text
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