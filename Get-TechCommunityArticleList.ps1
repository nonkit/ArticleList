# Get-TechCommunityArticleList.ps1 - Get Article List from Microsoft Tech Community Blog
# Version 0.5
# Copyright © 2019 Nonki Takahashi.  The MIT License.

# Usage:
# .\Get-TechCommunityArticleList [SmallBasic | EducationBlog | AzureDevCommunityBlog [yyyy [q [yyyy [q]]]]]

# History:
#  0.5  2019-06-12 Supported date and author before 2019-02-12.
#  0.4  2019-06-08 Changed output from text to object.
#  0.3  2019-06-07 Renamed to Get-TechCommunityArticleList.
#  0.2  2019-05-27 Rewrote Get-BlogInfo.
#  0.1a 2019-05-26 Created as Get-Calendar.

# dot source
. ($PSScriptRoot + '\NetworkLib.ps1')

function Get-ArticleInfo {
    # param $script:iSite - index of site information arrays
    # param $script:ym0 - year and month from
    # param $script:ym1 - year and month to
    # return article object array
    $auth = $a[$script:iSite]
    $long = $l[$script:iSite]
    $short = $s[$script:iSite]
    $tagB = $t[$script:iSite]
    $site = 'https://techcommunity.microsoft.com' 
    $url = '{0}/t5/{1}/bg-p/{2}' -f $site, $long, $short
    $nArticle = 0
    $maxPage = 1
    $stack = New-Object System.Collections.Stack
    for ($page = 1; $page -le $maxPage; $page++) {
        $article = @{}
        # get web page contents
        if ($page -eq 1) {
            $pg = ''
        } else {
            $pg = '/page/' + $page
        }
        $buf = Get-WebPageContents ($url + $pg)
        $script:p = 0
        $eod = $false
        $tag = 'exists'
        while ((-not $eod) -and $tag) {
            # link to a post
            $tag = Find-Tag -tagName 'a' -class 'page-link lia-link-navigation lia-custom-event'
            if ($tag) {
                $article['url'] = $script:attr['href']
                $article['title'] = $script:txt.Trim()
                # author and date
                $tag = Find-Tag -tagName 'div' -class 'author-details'
            }
            if ($tag) {
                $dig = $false
                $stack.Push($buf)
                $stack.Push($script:p)
                $buf = $tag
                $script:p = 0
                $tag = Find-Tag -tagName 'a'
                if ($tag) {
                    if ($auth.ContainsKey($script:txt)) {
                        $article['by'] = $auth[$script:txt]
                    } else {
                        $article['by'] = $script:txt
                    }
                    $tag = Find-Tag -tagName 'span' 
                }
                if ($tag) {
                    $tag = Find-Tag -tagName 'span' 
                }
                if ($tag) {
                    $article['year'] = $script:txt.Substring(6, 4)
                    $article['month'] = $script:txt.Substring(0, 2)
                    $article['day'] = $script:txt.Substring(3, 2)
                    $ym = [int]($article['year'] + $article['month'])
                    $ymd = [int]($article['year'] + $article['month'] + $article['day'])
                    if (($short -eq 'SmallBasic') -and ($ymd -eq 20190212)) {
                        $dig = $true
                    }
                }
                $script:p = $stack.Pop()
                $buf = $stack.Pop()
                if ($dig) {
                    # dig author and date
                    $tag = Find-Tag -tagName 'div' -class 'blog-article-teaser-wrapper'
                    $pd = $script:txt.IndexOf('MSDN on')
                    $pa = $script:txt.IndexOf('Authored')
                    if ((0 -le $pd) -and (0 -le $pa)) {
                        $date = Get-Date $script:txt.SubString($pd + 8, $pa - ($pd + 9))
                        $au = $script:txt.SubString($pa + 12, 19)
                    } else {
                        $stack.Push($buf)
                        $stack.Push($script:p)
                        $buf = Get-WebPageContents ($site + $article['url'])
                        $script:p = 0
                        # dig further author and date
                        $tag = Find-Tag -tagName 'STRONG'
                        $pd = $script:txt.IndexOf('MSDN on')
                        $date = Get-Date $script:txt.SubString($pd + 8)
                        $tag = Find-Tag -tagName 'I'
                        $pa = $script:txt.IndexOf('Authored')
                        $au = $script:txt.SubString($pa + 12)
                        $script:p = $stack.Pop()
                        $buf = $stack.Pop()
                    }
                    $article['year'] = [string]($date.year)
                    $article['month'] = '{0:00}' -f $date.month
                    $article['day'] = '{0:00}' -f $date.day
                    $ym = [int]($article['year'] + $article['month'])
                    $article['by'] = $au
                    foreach ($key in $auth.keys) {
                        if ($au.StartsWith($key)) {
                            $article['by'] = $auth[$key]
                            break
                        }
                    }
                }
                if ($tag -and ($script:ym0 -le $ym) -and ($ym -le $script:ym1)) {
                    $article['n'] = ++$nArticle
                    # article
                    [PSCustomObject]$article
                } elseif ($ym -lt $script:ym0) {
                    $eod = $true
                }
            }
        }
        if (-not $eod) {
            # next page
            $tag = Find-Tag -tagName 'a' -class ('lia-link-navigation lia-js-data-pageNum-{0} lia-custom-event' -f ($page + 1))
            if ($tag) {
                $maxPage = $page + 1
            }
        }
    }
}

function Initialize-SiteTable {
    $script:s = @()
    $script:l = @()
    $script:a = @()
    $script:t = @()
    # Small Basic Blog
    $auth = @{}
    $auth['Ed Price - MSFT'] = 'Ed'
    $auth['Ed Price'] = 'Ed'
    $auth['Ed'] = 'Ed'
    $auth['Jadamelio'] = 'jadamelio'
    $auth['Jibba Jabba'] = 'Rick Murphy'
    $auth['Katelyn Schoedl'] = 'Katelyn Schoedl'
    $auth['LitDev'] = 'LitDev'
    $auth['Liz Bander'] = 'Liz Bander'
    $auth['Michael'] = 'Michael Scherotter'
    $auth['Noah Buscher'] = 'Noah Buscher'
    $auth['Nonki Takahashi']  = 'Nonki'
    $auth['NonkiTakahashi']  = 'Nonki'
    $auth['Nonki']  = 'Nonki'
    $auth['Qazwsxedc Qazwsxedc'] = 'Noah Buscher'
    $auth['Ray Fast'] = 'Ray Fast'
    $auth['Rick Murphy'] = 'Rick Murphy'
    $auth['Sandra Aldana - MSFT'] = 'Sandra Aldana'
    $auth['Sandra Aldana'] = 'Sandra Aldana'
    $auth['Synergist'] = 'Synergist'
    $auth['Vijaye Raji'] = 'Vijaye Raji'
    $auth['Yan Grenier - MTFC'] = 'Yan Grenier'
    $auth['Yan Grenier'] = 'Yan Greier'
    $auth['Yan'] = 'Yan Grenier'
    $script:s += 'SmallBasic'
    $script:l += 'Small-Basic-Blog'
    $script:a += $auth
    $script:t += ''
    # Education Blog
    $script:s += 'EducationBlog'
    $script:l += 'Edication-Blog'
    $script:a += @{}
    $script:t += ''
    # Azure Development Community Blog
    $script:s += 'AzureDevCommunityBlog'
    $script:l += 'Azure-Developer-Community-Blog'
    $script:a += @{}
    $script:t += ''
    # /t5/tag/Vijaye%20Raji/tg-p/board-id/SmallBasic
}

function Test-Arg ($myArgs) {
    # param $s - short name array
    # param $myArgs - arguments array
    # return $script:site - site short name
    # return $script:ym0 - year and month from
    # return $script:ym1 - year and month to
    # return $script:msg - error message
    # return $script:err - $true if error
    # return $script:iSite - site index
    $script:err = $false
    # check site
    $script:site = $myArgs[0]
    if (-not $script:site) {
        $script:site = 'SmallBasic'
    }
    for ($i = 0; $i -lt $s.Length; $i++) {
        if ($script:site -eq $s[$i]) {
            break
        }
    }
    if ($s.Length -le $i) {
        $script:msg = 'Usage: .\Get-Calendar [SmallBasic | EducationBlog | AzureDevCommunityBlog [yyyy [q [yyyy [q]]]]]'
        $script:err = $true
    }
    $script:iSite = $i
    if (-not $script:err) {
        $today = Get-Date
        # check year from
        $script:y0 = $myArgs[1]
        if (-not $script:y0) {
            $script:y0 = $today.Year
            $script:y0 = 2008
        }
        if ($script:y0 -lt 1) {
            $script:msg = 'Illeagal from year (' + $script:y0 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check year to
        $script:y1 = $myArgs[3]
        if (-not $script:y1) {
            $script:y1 = $today.Year
        }
        if ($script:y1 -lt 1) {
            $script:msg = 'Illeagal to year (' + $script:y1 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check quoter from
        $script:q0 = $myArgs[2]
        if (-not $script:q0) {
            $script:q0 = 1
        }
        if (($script:q0 -lt 1) -or (4 -lt $script:q0)) {
            $script:msg = '"Illeagal from quoter (' + $script:q0 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check quoter to
        $script:q1 = $myArgs[4]
        if (-not $script:q1) {
            $script:q1 = 4
        }
        if (($script:q1 -lt 1) -or (4 -lt $script:q1)) {
            $script:msg = '"Illeagal from quoter (' + $script:q1 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        $script:m0 = ($script:q0 - 1) * 3 + 1
        $script:m1 = ($script:q1 - 1) * 3 + 3
        $script:ym0 = $script:y0 * 100 + $script:m0
        $script:ym1 = $script:y1 * 100 + $script:m1
    }
}

Initialize-SiteTable
Test-Arg $args
if ($err) {
    Write-Host $msg
    return
}
Get-ArticleInfo
