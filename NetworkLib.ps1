# NetworkLib.ps1 - Network Library
# Version 0.3
# Copyright © 2019 Nonki Takahashi.  The MIT License.

function Convert-Text ($in) {
    # Convert &*; to unicode character
    # param $in - text to convert
    # return - text converted
    if ($in) {
        $out = ''
        while ($in -and (0 -lt ($c = $in.IndexOf('&'))) `
            -and (0 -lt ($l = ($in.Substring($c)).IndexOf(';')))) {
            $kw = $in.Substring($c + 1, $l - 1)
            if ($kw.StartsWith('#') -and ($kw.Length -le 4)) {
                $to = [char][byte]($kw.Substring(1, $kw.Length - 1))
            } elseif ($kw.StartsWith('#') -and ($kw.Length -le 6)) {
                $to = [char][int32]($kw.Substring(1, $kw.Length - 1))
            } elseif ($kw -eq 'quot') {
                $to = '"'
            } elseif ($kw -eq 'amp') {
                $to = '&'
            } else {
                $to = '&'
                $l = 0
            }
            $out += $in.Substring(0, $c) + $to
            $in = $in.Substring($c + $l + 1)
        }
        $out + $in
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
        $pTag = ($buf.Substring($p)).IndexOf('<' + $tagName)
        if (0 -le $pTag) {
            $pTag += $p
            $len = ($buf.Substring($pTag)).IndexOf('/' + $tagName + '>')
            if (0 -le $len) {
                # tag may be different
                $findNext = $true
                $lTag = $tag.Length + ('/' + $tagName + '>').Length
                $len += $lTag
                $tag = $buf.Substring($pTag, $len)
                Get-AttrAndText $tag
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

function Get-AttrAndText ($tag) {
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
                    $script:attr[$tag.Substring($pTag, $pEq - $pTag)] = $txt
                    $pTag = $pQ + 2
                }
            } else {
                # to avoid hang with no quotes after equal
                $txt = $tag.Substring($pEq + 2, $pEnd - $pEq - 2)
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
            $script:txt += $tag.Substring($pTag)
            $pTag = $len
        } else {
            # '</' found
            $pL += $pTag
            $script:txt += $tag.Substring($pTag, $pL - $pTag)
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
    if ($script:txt) {
        $script:txt = Convert-Text $script:txt
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
