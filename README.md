
<!-- README.md is generated from README.Rmd. Please edit that file -->

# chinese-countryname-regex

<!-- badges: start -->
<!-- badges: end -->

Use overview table from Wikipedia. Caveats: - does not contain any
variants (e.g., 刚果（金）) - contains errors (Ghana’s full name is
written with the traditional character while the short name has the
simplified one)

So I use the table to visit each site individually.

The localized Wikipedia pages differ by more than just
character-by-character translations. See mainland vs. Taiwan:

> 瓦努阿图共和国（法语：République de Vanuatu、英语：Republic of
> Vanuatu、比斯拉马语：Ripablik blong Vanuatu，台湾译作万那杜）
> 通称瓦努阿图，…

> 萬那杜共和國（法語：République de Vanuatu、英語：Republic of
> Vanuatu、比斯拉馬語：Ripablik blong
> Vanuatu，中國大陸、香港、澳門、新加坡譯作瓦努阿圖） 通稱萬那杜，…

So from the standpoint of the mainland, “Wannuatu” would be the short
name and “Wannatu” a variant; whereas from Taiwan’s perspective, the
opposite would be true. Note that the full country name also reflects
this difference (Wannuatu Gongheguo vs. Wannatu Gongheguo).

So if I collect short and full country names as well as variants for
each type of Chinese, the corresponding entries will differ by more than
just a character-by-character translation.

# different unicode character, invisible

identical(“阿布哈茲”,“阿布哈兹”)

# converting the regex into traditional (without specifying the exact variant) works in most cases but regexes become very long and hard to maintain (especially because someone might delete what seems like a duplicate but invisibly refers to different unicode characters)

str_detect(“阿布哈茲”, converter(S2T)\[“阿(布哈\|柏克)兹”\])

Therefore, first converting to simplified (with the same engine that I
used to create the regexes) is prefered.

variant \<- c( “大陆简体” = “zh-cn”, “香港繁體” = “zh-hk”, “澳門繁體” =
“zh-mo”, “大马简体” = “zh-my”, “新加坡简体” = “zh-sg”, “臺灣正體” =
“zh-tw” )
