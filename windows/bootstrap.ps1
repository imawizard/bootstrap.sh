if (!(Get-Command "scoop" -ErrorAction SilentlyContinue)) {
    irm get.scoop.sh | iex
}

if (!(Get-Command "autohotkey" -ErrorAction SilentlyContinue)) {
    scoop install autohotkey
}

autohotkey bootstrap.ahk
