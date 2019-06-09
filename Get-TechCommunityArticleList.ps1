# Get-TechCommunityArticleList.ps1 - Get Article List from Microsoft Tech Community Blog
# Version 0.4
# Copyright © 2019 Nonki Takahashi.  The MIT License.

# Usage:
# .\Get-TechCommunityArticleList [SmallBasic | EducationBlog | AzureDevCommunityBlog [yyyy [q [yyyy [q]]]]]

# History:
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
    $url = 'https://techcommunity.microsoft.com/t5/{0}/bg-p/{1}' -f $long, $short
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
        $tag = 'found'
        while ($tag) {
            # link to a post
            $tag = Find-Tag -tagName 'a' -class 'page-link lia-link-navigation lia-custom-event'
            if ($tag) {
                $article['url'] = $script:attr['href']
                $article['title'] = $script:txt.Trim()
                # author and date
                $tag = Find-Tag -tagName 'div' -class 'author-details'
            }
            if ($tag) {
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
                    if (($script:ym0 -le $ym) -and ($ym -le $script:ym1)) {
                        $article['#'] = ++$nArticle
                        # article
                        [PSCustomObject]$article
                    } elseif ($ym -le $script:ym0) {
                        $tag = ''
                    }
                }
                $script:p = $stack.Pop()
                $buf = $stack.Pop()
            }
        }
        # next page
        $tag = Find-Tag -tagName 'a' -class ('lia-link-navigation lia-js-data-pageNum-{0} lia-custom-event' -f ($page + 1))
        if ($tag) {
            $maxPage = $page + 1
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
    $auth['Ed Price'] = 'Ed'
    $auth['Ed Price - MSFT'] = 'Ed'
    $auth['litdev'] = 'LitDev'
    $auth['Qazwsxedc Qazwsxedc'] = 'Noar Buscher'
    $auth['NonkiTakahashi']  = 'Nonki'
    $auth['Nonki Takahashi']  = 'Nonki'
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

function Initialize-Cal {
    # Calender | Initialize days of month
    $script:dom = @(31, 28, 31, 30, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    $script:name = @('January', 'February', 'March', 'April', 'May', 'June', `
        'July', 'August', 'September', 'October', 'November', 'December')
    $script:week = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
    $script:sp = @{}
    for ($n = 8; $n -le 20; $n += 4) {
        $script:sp[$n] = ' ' * $n
    }
}

function Test-Arg ($myArgs) {
    # param $s - short name array
    # param $myArgs - arguments array
    # return $script:site - site short name
    # return $script:yq0 - year and quoter from
    # return $script:yq1 - year and quoter to
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
        if (-not $y0) {
            $script:y0 = $today.Year
        }
        if ($y0 -lt 1) {
            $script:msg = 'Illeagal from year (' + $y0 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check year to
        $script:y1 = $myArgs[3]
        if (-not $y1) {
            $script:y1 = $today.Year
        }
        if ($y1 -lt 1) {
            $script:msg = 'Illeagal to year (' + $y1 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check quoter from
        $script:q0 = $myArgs[2]
        if (-not $q0) {
            $script:q0 = 1
        }
        if (($q0 -lt 1) -or (4 -lt $q0)) {
            $script:msg = '"Illeagal from quoter (' + $q0 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        # check quoter to
        $script:q1 = $myArgs[4]
        if (-not $q1) {
            $script:q1 = 4
        }
        if (($q1 -lt 1) -or (4 -lt $q1)) {
            $script:msg = '"Illeagal from quoter (' + $q1 + ')'
            $script:err = $true
        }
    }
    if (-not $err) {
        $script:m0 = ($q0 - 1) * 3 + 1
        $script:m1 = ($q1 - 1) * 3 + 3
        if (9 -lt $m0) {
            $script:ym0 = [string]$y0 + [string]$m0
        } else {
            $script:ym0 = [string]$y0 + '0' + [string]$m0
        }
        if (9 -lt $m1) {
            $script:ym1 = [string]$y1 + [string]$m1
        } else {
            $script:ym1 = [string]$y1 + '0' + [string]$m1
        }
    }
}

Initialize-SiteTable
"$($args[0]) $($args[1]) $($args[2]) $($args[3]) $($args[4])"
Test-Arg $args
if ($err) {
    Write-Host $msg
    return
}
"$script:y0 $script:q0 $script:m0 $script:ym0"
"$script:y1 $script:q1 $script:m1 $script:ym1"
Initialize-Cal
Get-ArticleInfo
