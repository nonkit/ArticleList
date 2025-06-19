# Get-Calendar.ps1 - Get HTML Calendar from Article Object
# Version 0.6
# Copyright © 2019-2020 Nonki Takahashi.  The MIT License.

# Usage:
# .\Get-Calendar -InputObject <PSObject[]>

# History:
#  0.6  2020-02-22 Bug fixed for the first day of a week. 
#  0.5  2019-06-15 Changed indent.
#  0.4  2019-06-14 Changed input from web to article object.
#  0.3  2019-06-07 Changed comments.
#  0.2  2019-05-27 Rewrote Get-BlogInfo.
#  0.1a 2019-05-26 Created.

[CmdletBinding()]
param (
[parameter(ValueFromPipeline = $true)]
[PSObject[]]$InputObject
)

begin {
    # days of month
    $dom = @(31, 28, 31, 30, 30, 31, 30, 31, 31, 30, 31, 30, 31)
    $week = @('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday')
    # column width [pt] for dates
    $c1w = 58.8
    # column width [pt] for days of week
    $cw = @{1=44.35;2=48.3;3=61.05;4=46.8;5=37.05;6=49.8;0=40.8}
    $sp = @{}
    for ($n = 8; $n -le 20; $n += 4) {
        $sp[$n] = ' ' * $n
    }
    $date0 = Get-Date
    $date1 = Get-Date '1900-01-01'
    $article = @()
}

process {
    foreach ($ar in $InputObject) {
        $article += $ar
        $date = Get-Date -Year $ar.year -Month $ar.month -Day $ar.day
        if ($date -lt $date0) {
            $date0 = $date
        }
        if ($date1 -lt $date) {
            $date1 = $date
        }
    }
}

end {
    $root = 'http://techcommunity.microsoft.com'
    $y0 = $date0.Year
    $y1 = $date1.Year
    $q0 = [int](($date0.Month - 1) / 3) + 1
    $q1 = [int](($date1.Month - 1) / 3) + 1
    for ($year = $y1; $y0 -le $year; $year--) {
        # days of month
        If ((($year % 4) -eq 0) -and ((($year % 100) -ne 0) -or (($year % 400) -eq 0))) {
            $dom[2 - 1] = 29
        } Else {
            $dom[2 - 1] = 28
        }
        # number of leap year
        $nol = [int](($year - 1) / 4) - [int](($year - 1) / 100) + [int](($year - 1) / 400)
        # week of year
        $woy = ($year + $nol) % 7 - 1
        if ($year -eq $y0) {
            $_q0 = $q0
        } else {
            $_q0 = 1
        }
        if ($year -eq $y1) {
            $_q1 = $q1
        } else {
            $_q1 = 4
        }
        for ($quoter = $_q1; $_q0 -le $quoter; $quoter--) {
            $buf = ''
            # header
            $yy = ([string]$year).Substring(2) -replace '0','_'
            $buf += '<h1><a name="Q' + $quoter + '_' + $yy + '">'
            $buf += '</a>Q' + $quoter + ' ' + $year + '</h1>' + "`r`n"
            $buf += '<p>Move mouse on an author to show the title '
            $buf += 'of the post.</p>' + "`r`n"
            $buf += '<table width="95%"'
            $buf += ' line-height: 18.83px; margin-left: 1px;'
            $buf += ' border-collapse: collapse; border="0"'
            $buf += ' cellspacing="0"'
            $buf += ' cellpadding="0">' + "`r`n"
            $buf += $sp[8] + '<tbody>' + "`r`n"
            $buf += $sp[12] + '<tr>' + "`r`n"
            $buf += $sp[16] + '<td valign="top"'
            $buf += ' style="padding: 0in 5.4pt; border: 1pt solid'
            $buf += ' windowtext; width: ' + $c1w + 'pt; background-color:'
            $buf += ' silver;">' + "`r`n"
            $buf += $sp[20] + '<strong>Dates:</strong><'
            $buf += '/td>' + "`r`n"
            for ($i = 1; $i -le 7; $i++) {
                $buf += $sp[16] + '<td valign="top"'
                $buf += ' style="border-color: windowtext windowtext'
                $buf += ' windowtext silver; padding: 0in 5.4pt; width:'
                $buf += ' ' + $cw[$i % 7] + 'pt;'
                $buf += ' border-top-width: 1pt; border-right-width: 1pt;'
                $buf += ' border-bottom-width: 1pt; border-top-style: solid;'
                $buf += ' border-right-style: solid; border-bottom-style:'
                $buf += ' solid; background-color: silver;">' + "`r`n"
                $buf += $sp[20] + '<strong>' + $week[$i % 7]
                $buf += '</strong></td>' + "`r`n"
            }
            $buf += $sp[12] + '</tr>' + "`r`n"
            $m0 = ($quoter - 1) * 3 + 1 # first month of quoter
            $m1 = $m0 + 2               # last month of quoter
            $doy = 0                    # days of year
            $nom = 1                    # number of month
            $iArticle = $article.Length - 1
            for ($m = $m0; $m -le $m1; $m++) {
                while ($nom -lt $m) {
                    $doy = $doy + $dom[$nom - 1]
                    $nom++
                }
                $w = ($doy + $woy) % 7      # day of week
                $d1 = ((8 - $w) % 7) + 1    # first monday
                for ($day = $d1; $day -le $dom[$m - 1]; $day += 7) {
                    # Dates: $m $day - $m2 $day2
                    $m2 = $m
                    $day2 = $day + 6
                    if ($dom[$m - 1] -lt $day2) {
                        $m2 = $m + 1
                        if (12 -lt $m2) {
                            $m2 = 1
                        }
                        $day2 -= $dom[$m - 1]
                    }
                    $buf += $sp[12] + '<tr>' + "`r`n"
                    $buf += $sp[16] + '<td valign="top"'
                    $buf += ' style="border-color: silver windowtext'
                    $buf += ' windowtext; padding: 0in 5.4pt; width: ' + $c1w + 'pt;'
                    $buf += ' border-right-width: 1pt; border-bottom-width: 1pt;'
                    $buf += ' border-left-width: 1pt; border-right-style: solid;'
                    $buf += ' border-bottom-style: solid; border-left-style:'
                    $buf += ' solid;">' + "`r`n"
                    $buf += $sp[20] + $m + '/' + $day + ' - ' + $m2 + '/' + $day2
                    $buf += '</td>' + "`r`n"
                    $d = $day
                    $_m = $m
                    # from Monday to Sunday
                    for ($i = 1; $i -le 7; $i++) {
                        $buf += $sp[16] + '<td valign="top"'
                        $buf += ' style="border-color: silver windowtext'
                        $buf += ' windowtext silver; padding: 0in 5.4pt; width:'
                        $buf += ' ' + $cw[$i % 7] + 'pt;'
                        $buf += ' border-right-width: 1pt; border-bottom-width: 1pt;'
                        $buf += ' border-right-style: solid; border-bottom-style:'
                        $post = ''
                        # check oldest article object
                        $_post = $article[$iArticle]
                        if ([int]($_post.year + $_post.month + $_post.day) -le ($year * 10000 + $m * 100 + $d)) {
                            # the article date is older than or equal to the date to output
                            while ((0 -lt $iArticle) -and ([int]($_post.year + $_post.month + $_post.day) -lt ($year * 10000 + $m * 100 + $d))) {
                                # get newest article to output 
                                $iArticle--
                                $_post = $article[$iArticle]
                            }
                            if (([int]$_post.year -eq $year) -and ([int]$_post.month -eq $m) -and ([int]$_post.day -eq $d)) {
                                # current article is equal to the date to output
                                # set the article object to $post
                                $post = $_post
                            }
                        }
                        if (-not $post) {
                            $buf += ' solid;">' + "`r`n"
                            $buf += $sp[20] + '&nbsp;</td>' + "`r`n"
                        } else {
                            $buf += ' solid;"' + "`r`n"
                            $buf += $sp[20] + 'title="' + $post.title
                            $buf += '">' + "`r`n"
                            $buf += $sp[20] + '<a href="' + $root + $post.url
                            $buf += '">' + $post.by + '</a></td>' + "`r`n"
                        }
                        $d++
                        if ($dom[$m - 1] -lt $d) {
                            $d = 1
                            $m++
                        }
                    }
                    $m = $_m
                    $buf += $sp[12] + '</tr>' + "`r`n"
                }
            }
            # footer
            $buf += $sp[8] + '</tbody>' + "`r`n"
            $buf += '</table>' + "`r`n"
            $buf += '<br>' + "`r`n"
            $buf
        }
    }
}
