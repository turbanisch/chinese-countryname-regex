prepare_regex <- function(countrynames_wide) {
  # convert everything to simplified and keep unique variants
  variants <- countrynames_wide %>%
    pivot_longer(
      cols = short_name:last_col(),
      names_to = "x",
      values_to = "name"
    ) %>%
    filter(!is.na(name)) %>%
    mutate(name = ropencc::converter(T2S)[name]) %>%
    distinct(iso3c, name)
  
  # remove variants that should not be matched by regex (e.g. outdated names), add missing ones
  variants <- variants %>% 
    # remove single characters, e.g. 港，澳
    filter(str_length(name) > 1L) %>% 
    # add names
    add_row(iso3c = "JEY", name = "泽尔西") %>% 
    add_row(iso3c = "TWN", name = "台湾") %>% 
    add_row(iso3c = "PCN", name = "皮特凯恩、亨德森、迪西和奥埃诺群岛") %>% 
    arrange(iso3c) %>% 
    # require Vigin Islands to include "American" or "British"
    filter(!(iso3c %in% c("VGB", "VIR") & !str_detect(name, "英属|美属"))) %>% 
    # 清朝史籍稱布魯克巴, remove
    filter(name != "布鲁克巴") %>% 
    # 國名直譯為冰封之島, remove
    filter(name != "冰封之") %>% 
    # 1501年之前很长一段历史时间被外界称波斯, remove
    filter(name != "波斯") %>% 
    # 古称溜山, remove
    filter(name != "溜山") %>% 
    # 毛利语：Aotearoa，奥特亚罗瓦, remove
    filter(name != "奥特亚罗瓦") %>% 
    # 舊称暹罗, remove
    filter(name != "暹罗")
  
  # add longest common substring as basis for regex
  variants %>%
    group_by(iso3c) %>%
    summarise(variant = list(c(name))) %>%
    mutate(common_string = map_chr(variant , PTXQC::LCSn)) %>%
    unnest_longer(variant) %>%
    # pre-fill regex if one of the variants is a substring of all other variants
    group_by(iso3c) %>%
    mutate(regex = if_else(common_string %in% variant, common_string, "")) %>% 
    ungroup()
}