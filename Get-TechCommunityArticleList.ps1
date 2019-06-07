# Get-TechCommunityArticleList.ps1 - Get Information from Microsoft Tech Community Blog
# Version 0.3
# Copyright © 2019 Nonki Takahashi.  The MIT License.

# Usage:
# .\Get-TechCommunityArticleList [SmallBasic | EducationBlog | AzureDevCommunityBlog [yyyy [q [yyyy [q]]]]]

# History:
#  0.3  2019-06-07 Renamed to Get-TechCommunityArticleList.
#  0.2  2019-05-27 Rewrote Get-BlogInfo.
#  0.1a 2019-05-26 Created as Get-Calendar.

# dot source
. ($PSScriptRoot + '\NetworkLib.ps1')

function Get-BlogInfo {
    # param $iBlog - index of blog information arrays
    # param $script:ym0 - year and month from
    # param $script:ym1 - year and month to
    # return $script:blog - blog post array
    $auth = $a[$iBlog]
    $long = $l[$iBlog]
    $blog = $b[$iBlog]
    $tagB = $t[$iBlog]
    $url = 'https://techcommunity.microsoft.com/t5/{0}/bg-p/{1}' -f $long, $blog
    $script:blog = @{}
    $nArticle = 0
    $maxPage = 1
    $stack = New-Object System.Collections.Stack
    for ($page = 1; $page -le $maxPage; $page++) {
        $post = @{}
        # get web page contents
        $url + '/page/' + $page
        $buf = Get-WebPageContents ($url + '/page/' + $page)
        $script:p = 0
        $tag = 'found'
        while ($tag) {
            # link to a post
            $tag = Find-Tag -tagName 'a' -class 'page-link lia-link-navigation lia-custom-event'
            if ($tag) {
                $post['url'] = $script:attr['href']
                $post['title'] = $script:txt.Trim()
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
                    $post['by'] = $script:txt
                    $tag = Find-Tag -tagName 'span' 
                }
                if ($tag) {
                    $tag = Find-Tag -tagName 'span' 
                }
                if ($tag) {
                    $post['date'] = $script:txt.Substring(0, 10) 
                    $post['#'] = ++$nArticle
                    $script:blog += @{$nArticle = $post}
                    # blog hash
                    '$post[''#''] = ''{0}''' -f $post['#']
                    '$post[''title''] = ''{0}''' -f $post['title']
                    '$post[''url''] = ''{0}''' -f $post['url']
                    '$post[''by''] = ''{0}''' -f $post['by']
                    '$post[''date''] = ''{0}''' -f $post['date']
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
    # /t5/tag/Vijaye%20Raji/tg-p/board-id/SmallBasic
}

function Initialize-BlogTable {
    $script:b = @()
    $script:l = @()
    $script:a = @()
    $script:t = @()
    # Small Basic Blog
    $auth = @{}
    $auth['Ed Price - MSFT'] = 'Ed'
    $auth['litdev'] = 'LitDev'
    $auth['Qazwsxedc Qazwsxedc'] = 'Noar Buscher'
    $auth['Nonki Takahashi']  = 'Nonki'
    $script:b += 'SmallBasic'
    $script:l += 'Small-Basic-Blog'
    $script:a += $auth
    $script:t += ''
    # Education Blog
    $script:b += 'EducationBlog'
    $script:l += 'Edication-Blog'
    $script:a += @{}
    $script:t += ''
    # Azure Development Community Blog
    $script:b += 'AzureDevCommunityBlog'
    $script:l += 'Azure-Developer-Community-Blog'
    $script:a += @{}
    $script:t += ''
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

function Test-Arg {
    # return $script:yq0 - year and quoter from
    # return $script:yq1 - year and quoter to
    # return $script:ym0 - year and month from
    # return $script:ym1 - year and month to
    # return $script:msg - error message
    # return $script:err - $true if error
    # return $script:iBlog - blog index
    $script:err = $false
    # check blog
    if (-not $blog) {
        $blog = 'SmallBasic'
    }
    for ($i = 0; $i -lt $b.Length; $i++) {
        if ($blog -eq $b[$i]) {
            break
        }
    }
    if ($b.Length -le $i) {
        $script:msg = 'Usage: .\Get-Calendar {SmallBasic | EducationBlog | AzureDevCommunityBlog} [yyyy [q [yyyy [q]]]]'
        $script:err = $true
    }
    $script:iBlog = $i
    if (-not $err) {
        $today = Get-Date
        # check year from
        $script:y0 = $script:args[1]
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
        $script:y1 = $script:args[3]
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
        $script:q0 = $script:args[2]
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
        $script:q1 = $script:args[4]
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

Initialize-BlogTable
$blog = $args[0]
Test-Arg
$url
if ($err) {
    Write-Host $msg
    return
}
"$y0 $q0 $m0"
"$y1 $q1 $m1"
Initialize-Cal
$sp[8] + '8'
$sp[12] + '12'
$sp[16] + '16'
Get-BlogInfo
