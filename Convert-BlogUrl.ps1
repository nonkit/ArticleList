# Convert-BlogUrl.ps1 - Convert Blog URL
# Version 0.1
# Copyright © 2019 Nonki Takahashi.  The MIT License.

# read old and new blog URL
$csv = Import-CSV '.\OldNew.csv'
$csv.Length
$csv[0]
$csv[$csv.Length - 1]
# read old html
$buf = Get-Content '.\BlogIndexOld2008-2018.html' -Encoding UTF8
$buf.Length
$buf[0]
# write new html
Set-Content '.\BlogIndexNew2008-2018.html' $buf -Encoding UTF8