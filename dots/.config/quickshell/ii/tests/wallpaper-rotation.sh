#!/usr/bin/env bash
set -euo pipefail

script=$(realpath "$(dirname "$0")/../scripts/colors/switchwall.sh")
testdir=$(mktemp -d)
trap 'rm -rf "$testdir"' EXIT
export XDG_CONFIG_HOME="$testdir/config" XDG_CACHE_HOME="$testdir/cache"
folder="$testdir/Обои #1"
video="$folder/"'other $wall "one".mp4'
config="$XDG_CONFIG_HOME/illogical-impulse/config.json"
mkdir -p "$folder/subdir.jpg" "${config%/*}" "$XDG_CONFIG_HOME/hypr/custom/scripts" "$testdir/bin"
for tool in bash basename dirname jq xargs echo bc mkdir mv cat chmod date sleep touch; do
    ln -s "$(type -P "$tool")" "$testdir/bin/$tool"
done
for tool in pkill gsettings; do
    ln -s "$(type -P true)" "$testdir/bin/$tool"
done
hyprctl() {
    if [[ "$1" == monitors ]]; then
        echo '[{"name":"test","focused":true,"scale":1,"x":0,"y":0,"height":1080}]'
    else
        echo '{"x":0,"y":0}'
    fi
}
export -f hyprctl

start_at() {
    jq -n --arg path "$1" '{background:{wallpaperPath:$path},appearance:{palette:{type:"scheme-content",accentColor:"#123456"},wallpaperTheming:{enableAppsAndShell:false}}}' > "$config"
}

expect_next() {
    PATH="$testdir/bin" "$script" --next --mode dark
    jq -e --arg path "$1" '.background.wallpaperPath == $path and .appearance.palette.accentColor == "#123456"' "$config" >/dev/null
}

touch "$folder/a.png" "$folder/a-dark.png" "$folder/notes.txt" "$folder/subdir.jpg/nested.png" "$video" "$folder/z #%.JPG"
start_at "$folder/a-dark.png"
expect_next "$folder/a.png"
expect_next "$folder/z #%.JPG"
expect_next "$folder/a-dark.png"
start_at "$folder/deleted.png"
expect_next "$folder/z #%.JPG"
start_at "$folder/subdir.jpg/nested.png"
expect_next "$folder/subdir.jpg/nested.png"
start_at "$testdir/missing/old.png"
expect_next "$testdir/missing/old.png"
start_at ""
expect_next ""

ffmpeg() { touch "${!#}"; }
mpvpaper() { printf '%s\n' "${!#}" > "$XDG_CACHE_HOME/played"; }
export -f ffmpeg mpvpaper
start_at "$folder/a.png"
expect_next "$video"
: > "$XDG_CACHE_HOME/played"
PATH="$testdir/bin" "$XDG_CONFIG_HOME/hypr/custom/scripts/__restore_video_wallpaper.sh"
[[ "$(< "$XDG_CACHE_HOME/played")" == "$video" ]]
