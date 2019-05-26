# NetworkLib.ps1 - Network Library
# Version 0.1
# Copyright © 2019 Nonki Takahashi.  The MIT License.

function Convert-Text {
    # Convert &*; to unicode character
    # param $txt
    # return $script:txt
    if ($txt) {
        while ($txt.Contains('&') -and $txt.Contains(';')) {
            $c = $txt.IndexOf('&')
            $l = ($txt.Substring($c)).IndexOf(';')
            $kw = $txt.Substring($c + 1, $l - 2)
            if ($kw.StartsWith('#')) {
                $txtMid = [char][byte]($kw.Substring(2))
            } elseif ($kw -eq 'quot') {
                $txtMid = '"'
            } else {
                $txtMid = ''
            }
            $txtLeft = $txt.Substring(0, $c - 1)
            $txtRight = $txt.Substring($c + $l)
            $txt = $txtLeft + $txtMid + $txtRight
        }
        $script:txt = $txt
    }
}

function Find-Tag ($tagName, $class, $rel, $id){
    # Find tag from html buffer
    # param $tagName - tag name
    # param $class - class name
    # param $rel - rel name
    # param $id - id
    # param $script:p - pointer for buffer
    # param $buf - html buffer
    # return $script:p - pointer for buffer
    # return - found tag
    $p = $script:p
    $pSave = $p
    $tag = ''
    $findNext = $true
    while ($findNext) {
        # tag may be not found
        $findNext = $false
        $pTag = ($buf.Substring($p)).IndexOf('<' + $tagName + ' ')
        if (0 -le $pTag) {
            $pTag += $p
            $len = ($buf.Substring($pTag)).IndexOf('/' + $tagName + '>')
            if (0 -le $len) {
                # tag may be different
                $findNext = $true
                $lTag = $tag.Length + ('/' + $tagName + '>').Length
                $len += $lTag
                $tag = $buf.Substring($pTag, $len)
                Get-AttrAndText
                if ($id) {
                    $value = $id
                    $target = 'id'
                } elseif ($class) {
                    $value = $class
                    $target = 'class'
                } else {
                    $value = $rel
                    $target = 'rel'
                }
                if ($attr[$target] -eq $value) {
                    # found the tag
                    $findNext = $false
                } else {
                    $tag = ''
                }
                $p = $pTag + $len
            }
        }
    }
    if ($tag -eq '') {
        $p = $pSave
    }
    $script:p = $p
    $tag
}

function Get-AttrAndText {
    # Get attributes and text from given tag
    # param $tag - given tag
    # return $script:attr{} - hash of attributes in the tag
    # return $script:txt - text in the tag
    $pTag = $tag.IndexOf(' ') + 1
    $pEnd = $tag.IndexOf('>')
    $script:attr = @{}
    while ($pTag -lt $pEnd) {
        $pEq = ($tag.Substring($pTag)).IndexOf('=')
        if (0 -le $pEq) {
            $pEq += $pTag
            $pQ = '''"'.IndexOf($tag.Substring($pEq + 1, 1))
            if (0 -le $pQ) {
                $Q = '''"'.Substring($pQ, 1)
                $pQ = ($tag.Substring($pEq + 2)).IndexOf($Q)
                if (0 -le $pQ) {
                    $pQ += ($pEq + 2)
                    $txt = $tag.Substring($pEq + 2, $pQ - $pEq - 2)
                    Convert-Text
                    $script:attr[$tag.Substring($pTag, $pEq - $pTag)] = $txt
                    $pTag = $pQ + 2
                }
            } else {
                # to avoid hang with no quotes after equal
                $txt = $tag.Substring($pEq + 2, $pEnd - $pEq - 2)
                Convert-Text
                $script:attr[$tag.Substring($pTag, $pEq - $pTag)] = $txt
                $pTag = $pEnd + 1
            }
        } else {
            $pTag = $pEnd + 1
        }
    }
    $len = $tag.Length
    $script:txt = ''
    while ($pTag -lt $len) {
        $pL = ($tag.Substring($pTag)).IndexOf('</')
        if ($pL -lt 0) {
            # '</' not found
            $script:txt = $script:txt + $tag.Substring($pTag)
            $pTag = $len
        } else {
            # '</' found
            $pL += $pTag
            $script:txt = $script:txt + $tag.Substring($pTag, $pL - $pTag)
            $pR = ($tag.Substring($pL)).IndexOf('>')
            if (0 -le $pR) {
                # '>' found
                $pTag += $pL
            } else {
                # '>' not found
                $pTag = $len
            }
        }
    }
}

function Get-WebPageContents($url) {
    # Simulates Small Basic NetWork.GetWebPageContents()
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $wc = New-Object System.Net.WebClient
    $st = $wc.OpenRead($url)
    $enc = [System.Text.Encoding]::GetEncoding('UTF-8')
    $sr = New-Object System.IO.StreamReader($st, $enc)
    $html = $sr.ReadToEnd()
    $sr.Close()
    $html
}
