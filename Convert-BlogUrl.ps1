# Convert-BlogUrl.ps1 - Convert Blog URL
# Version 0.3
# Copyright © 2019 Nonki Takahashi.  The MIT License.

function Convert-Url ($in) {
    if ($in.Contains('a href="')) {
        $s = $in.IndexOf('a href="') + 8
        $len = ($in.Substring($s)).IndexOf('"')
        $ipath = $in.Substring($s, $len)
        $ip = $ipath -replace $oldPath, ''
        $found = ($csv | Where-Object {$_.old -eq $ip})
        if ($found) {
            Write-Host $ipath -ForegroundColor Red
            $opath = ($newPath + $found.new)
            Write-Host $opath -ForegroundColor Green
            $in -replace $ipath, $opath
        } else {
            $in
        }
    } else {
        $in
    }
}
if ($args.Length -lt 2) {
    Write-Host 'Usage: PS> .\Convert-BlogUrl <Old> <New>'
    exit
}
$oldFile = $args[0]
$newFile = $args[1]
# initialize variables
$oldPath = 'https://blogs.msdn.microsoft.com/smallbasic/'
$newPath = 'https://techcommunity.microsoft.com/t5/Small-Basic-Blog/'
# read old and new blog URL
$csv = Import-CSV '.\OldNew.csv'
# read old html
$buf = Get-Content $oldFile -Encoding UTF8
$out = @()
for ($i = 0; $i -lt $buf.Length; $i++) {
    if (($i % 1000) -eq 0) {
        $i
    }
    $out += (Convert-Url $buf[$i])
}
# write new html
Set-Content $newFile $out -Encoding UTF8
