
<!-- README.md is generated from README.Rmd. Please edit that file -->

``` r
library(tidyverse)
walk(fs::dir_ls("R/"), source)
```

# Regular expressions to match country names in Chinese

<!-- badges: start -->
<!-- badges: end -->

## Challenges

Coming up with regular expressions to match country names in Chinese is
slightly more involved than for other languages. The reason is that
different parts of the world use different variants of Chinese, beyond
the basic distinction between simplified and traditional characters.
Mainland China, Malaysia and Singapore all use simplified characters
whereas Hong Kong, Macau and Taiwan continue to use traditional
characters - but local usage may vary within each group.

This is especially true for proper names like country names. Not only
can they vary character by character depending on the script that is
used, but they might also reflect different (phonetic) transliterations
or refer to another name altogether. Here are some examples for each
case:

1.  **Different scripts.** Germany is referred to as *Deguo* 德国 in
    Mainland China and 德國 in Taiwan – where 国 is the simplified
    character corresponding to 國, easy. However, there are some less
    obvious cases, as we will see below.
2.  **Different transliterations**. Many country names have been
    phonetically adapted from other languages and translators in every
    Chinese-speaking region have taken their artistic liberties when
    doing so. For example, Hong Kongers refer to Barbados as *Babaduosi*
    巴巴多斯 whereas people from Taiwan call it *Babeiduo* 巴貝多.
3.  **Alternative names**. Instead of converting a country name
    according to its sound, Chinese-speaking people in some regions have
    also opted to convert the original meaning of the country name into
    Chinese. For example, Montenegro is *Heishan* 黑山 (“black
    mountain”) in Mainland China. People on Taiwan, on the other hand,
    kept their phonetic transliteration *Mengteneigeluo* 蒙特內哥羅.

## Proposed solution

The issue of different scripts could be solved in two ways: either by
harmonizing the scripts by some automatic conversion procedure or
writing complex regular expressions that match any script. I discuss the
two below in the section on testing my regular expressions and focus on
the second issue here.

The issues of different transliterations and alternative country names
call for the same solution: coming up with a list of country names from
each Chinese-speaking region. The regular expressions need to be able to
match each element of these lists. Luckily, Wikipedia not only records
the official country name, the colloquial country name as well as name
variants; it does so for flavors of Chinese from Mainland China, Hong
Kong, Macau, Malaysia, Singapore and Taiwan.

![](img/language_dropdown.png)

Wikipedia even offers an [overview
page](https://zh.wikipedia.org/zh-cn/世界政區索引) with full and short
country names. This page alone is not sufficient for two reasons. First,
it does not include any name variants; second, it contains errors
(Ghana’s full name is written using the traditional character 迦 while
the short name contains the simplified 加).

But since the overview page provides links to the individual country
pages, it can serve as an entry point for web crawling. Wikipedia’s
localization not only takes care of character-by-character conversion
but also reflects differences in usage described above, as the following
example of Montenegro shows:

![Mainland](img/montenegro_mainland.png)

![Taiwan](img/montenegro_taiwan.png)

## Procedure

1.  Scrape country names from each country page (in each language
    variant). I use the article heading as the short name, the first
    name in the first sentence as the official name, and all other names
    in the first sentence (typeset in bold) as name variants.
2.  Convert all country names to simplified characters and identify the
    longest common substring. This substring serves as a basis for
    developing regular expressions manually. If a substring entirely
    matches one of the country name, I use it as the regular expression
    and overwrite it only in case of ambiguity (e.g., Congo 刚果).
3.  Manually develop regular expressions including lookarounds to
    distinguish the various Guineas and other shenanigans. Out of the
    variants in my list, I only ignore transliterations from the local
    language (e.g., *Aoteyaluowa* 奥特亚罗瓦 for New Zealand) and the
    ones that are obviously outdated (such as *Bulukeba* 布魯克巴,
    apparently used for Bhutan during the Qing dynasty). The resulting
    regular expressions should be fairly specific but assume that the
    input is a country name of some sort. Otherwise, the regular
    expression for Western Sahara (`西撒哈拉|撒哈?拉.*民主共和国`) might
    also match the geographical term for the western part of the Sahara
    desert.  
4.  Merge ISO3 codes and regular expressions to the conversion table
    comprising all short and full names in all language variants.
5.  Test the regular expressions against all variants (in simplified
    Chinese) below.

## Tests

``` r
# which entries could not be matched?
matched %>% filter(is.na(short_name_en.y))
#> # A tibble: 6 × 4
#>   short_name_en.x     variant    short_name_en.y regex
#>   <chr>               <chr>      <chr>           <chr>
#> 1 Bhutan              布鲁克巴   <NA>            <NA> 
#> 2 Congo (Brazzaville) 刚果       <NA>            <NA> 
#> 3 Iceland             冰封之岛   <NA>            <NA> 
#> 4 Iran                波斯       <NA>            <NA> 
#> 5 Maldives            溜山       <NA>            <NA> 
#> 6 New Zealand         奥特亚罗瓦 <NA>            <NA>
```

Only the ones that I removed on purpose: outdated names (布鲁克巴, 波斯,
溜山), literal translations (冰封之岛, 奥特亚罗瓦) and ambiguous ones
(刚果)

``` r
# check if countries were matched more than once
matched %>% janitor::get_dupes(short_name_en.x, variant)
#> # A tibble: 0 × 5
#> # … with 5 variables: short_name_en.x <chr>, variant <chr>, dupe_count <int>,
#> #   short_name_en.y <chr>, regex <chr>
```

``` r
# which entries were matched to a wrong country?
matched %>%
  filter(short_name_en.x != short_name_en.y)
#> # A tibble: 1 × 4
#>   short_name_en.x variant short_name_en.y regex              
#>   <chr>           <chr>   <chr>           <chr>              
#> 1 Taiwan          中国    China           中国|中华人民共和国
```

only Taiwan’s variant 中国

## Overview

``` r
variant <- c(
  "大陆简体" = "zh-cn",
  "香港繁體" = "zh-hk",
  "澳門繁體" = "zh-mo",
  "大马简体" = "zh-my",
  "新加坡简体" = "zh-sg",
  "臺灣正體" = "zh-tw"
)
```

## Making regexes work for traditional Chinese

``` r
# different unicode character, invisible
identical("阿布哈茲","阿布哈兹")
#> [1] FALSE

# converting the regex into traditional (without specifying the exact variant) works in most cases but regexes become very long and hard to maintain (especially because someone might delete what seems like a duplicate but invisibly refers to different unicode characters)
# str_detect("阿布哈茲", converter(S2T)["阿(布哈|柏克)兹"])
```

Therefore, first converting to simplified (with the same engine that I
used to create the regexes) is prefered.
