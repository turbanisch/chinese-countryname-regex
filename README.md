
<!-- README.md is generated from README.Rmd. Please edit that file -->

``` r
library(tidyverse)
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

## Solutions

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
the short name contains the simplified 加). But since the overview page
provides links to the individual country pages, it can serve as an entry
point for web crawling.

From each country page (in each language variant), I scrape the article
heading as the short name, the first name in the first sentence as the
official name, and all other names in the first sentence (typeset in
bold) as name variants. Wikipedia’s localization not only takes care of
character-by-character conversion but also reflects differences in usage
described above, as the following example of Montenegro shows:

![Mainland](img/montenegro_mainland.png)

![Taiwan](img/montenegro_taiwan.png)

``` r
# different unicode character, invisible
identical("阿布哈茲","阿布哈兹")
#> [1] FALSE

# converting the regex into traditional (without specifying the exact variant) works in most cases but regexes become very long and hard to maintain (especially because someone might delete what seems like a duplicate but invisibly refers to different unicode characters)
# str_detect("阿布哈茲", converter(S2T)["阿(布哈|柏克)兹"])
```

Therefore, first converting to simplified (with the same engine that I
used to create the regexes) is prefered.

variant \<- c( “大陆简体” = “zh-cn”, “香港繁體” = “zh-hk”, “澳門繁體” =
“zh-mo”, “大马简体” = “zh-my”, “新加坡简体” = “zh-sg”, “臺灣正體” =
“zh-tw” )
