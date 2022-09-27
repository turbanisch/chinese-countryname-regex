find_unique_simplified_variants <- function(countrynames_df) {
  # convert to simplified Chinese, keep unique variants
  variants <- countrynames_df %>%
    pivot_longer(
      cols = short_name:last_col(),
      names_to = "x",
      values_to = "name"
    ) %>%
    filter(!is.na(name)) %>%
    mutate(name = ropencc::converter(T2S)[name]) %>%
    distinct(iso3c, name)
  
  # keep only variants that should be matched by regular expressions (e.g., ignore outdated names)
  variants %>% 
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
    filter(name != "冰封之地") %>% 
    # 1501年之前很长一段历史时间被外界称波斯, remove
    filter(name != "波斯") %>% 
    # 古称溜山, remove
    filter(name != "溜山") %>% 
    # 毛利语：Aotearoa，奥特亚罗瓦, remove
    filter(name != "奥特亚罗瓦") %>% 
    # 舊称暹罗, remove
    filter(name != "暹罗") %>% 
    # Congo ambiguous (DRC vs. Republic)
    filter(name != "刚果") %>% 
    # 旧称尤宁群岛（Union Islands）
    filter(name != "尤宁群岛") %>% 
    # 圭亚那 belongs to GUY
    filter(!(iso3c == "GUF" & name == "圭亚那")) %>% 
    # ambiguous between MAF and SXM
    filter(name != "圣马丁")
}