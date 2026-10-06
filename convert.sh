#!/bin/bash
# Converts your own copies of Microsoft Dancer animations into Touch Bar frames.
# No dancer artwork is distributed with this repo.
#
# Usage: ./convert.sh <dancer.cab | dancer.Dnc | folder> [...]
#   A folder converts every dancer in it, preferring the large (_l) version of each.
# Output: ~/Library/Application Support/Pock/Dancers/<Name>/frames/frame_00001.png ... plus meta.json
#   (set DANCERS_DIR to put them elsewhere). The widget picks new dancers up without a rebuild.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
OUT_ROOT="${DANCERS_DIR:-$HOME/Library/Application Support/Pock/Dancers}"
FPS=30
OUT_H=60   # the Touch Bar is 30pt / 60px high at 2x

for tool in ffmpeg ffprobe bsdtar python3; do
    command -v "$tool" >/dev/null || { echo "$tool is required (brew install ffmpeg)" >&2; exit 1; }
done

lower() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

# "Amanda_L.cab" -> "Amanda", "cobey_l.cab" -> "Cobey"
dancer_name() {
    local b; b=$(basename "$1"); b=${b%.*}
    case "$(lower "$b")" in *_l|*_s) b=${b%??} ;; esac
    printf '%s%s' "$(printf '%s' "${b:0:1}" | tr 'a-z' 'A-Z')" "${b:1}"
}

convert_dnc() {
    local dnc="$1" name="$2" mask="${3:-}" dir="$OUT_ROOT/$2"
    echo "== $name"

    local dims W H
    dims=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$dnc")
    W=${dims%,*}; H=${dims#*,}

    # Find the area the dancer occupies across the whole clip. The .Dat alpha mask is a clean
    # silhouette, so prefer it; otherwise fall back to the non-black part of the colour video.
    local src="$dnc" thr=24
    if [ -n "$mask" ] && [ "$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0 "$mask")" = "$dims" ]; then
        src="$mask"; thr=128
    fi
    local x1 x2 y1 y2
    if ! read -r x1 x2 y1 y2 < <(python3 "$ROOT/detect_crop.py" "$src" "$W" "$H" "$thr"); then
        echo "  couldn't find the dancer in the video; skipping" >&2
        return 1
    fi

    # 2px margin, clamped, even dimensions.
    x1=$(( x1 > 2 ? x1 - 2 : 0 )); y1=$(( y1 > 2 ? y1 - 2 : 0 ))
    x2=$(( x2 + 2 < W ? x2 + 2 : W - 1 )); y2=$(( y2 + 2 < H ? y2 + 2 : H - 1 ))
    local cw=$(( x2 - x1 + 1 )) ch=$(( y2 - y1 + 1 ))
    cw=$(( cw - cw % 2 )); ch=$(( ch - ch % 2 ))
    local ow=$(( (OUT_H * cw + ch / 2) / ch )); ow=$(( ow - ow % 2 ))
    echo "  crop ${cw}x${ch} at ${x1},${y1} -> ${ow}x${OUT_H}px"

    rm -rf "$dir"; mkdir -p "$dir/frames"
    ffmpeg -nostdin -v error -y -i "$dnc" \
        -vf "crop=$cw:$ch:$x1:$y1,fps=$FPS,scale=$ow:$OUT_H:flags=lanczos" \
        "$dir/frames/frame_%05d.png"

    local count; count=$(ls "$dir/frames" | wc -l | tr -d ' ')
    printf '{"name":"%s","width":%d,"height":%d,"count":%d,"fps":%d}\n' \
        "$name" "$ow" "$OUT_H" "$count" "$FPS" > "$dir/meta.json"
    echo "  wrote $count frames"
}

convert_file() {
    local f="$1"
    case "$(lower "$f")" in
        *.dnc)
            local mask; mask=$(find "$(dirname "$f")" -maxdepth 1 -iname "$(basename "${f%.*}").dat" | head -1)
            convert_dnc "$f" "$(dancer_name "$f")" "$mask" || true ;;
        *.cab)
            local tmp dnc mask; tmp=$(mktemp -d)
            bsdtar -xf "$f" -C "$tmp" --include='*.[Dd][Nn][Cc]' --include='*.[Dd][Aa][Tt]' 2>/dev/null || true
            dnc=$(find "$tmp" -iname '*.dnc' | head -1)
            mask=$(find "$tmp" -iname '*.dat' | head -1)
            if [ -n "$dnc" ]; then convert_dnc "$dnc" "$(dancer_name "$f")" "$mask" || true
            else echo "== $(basename "$f"): no animation inside, skipping"; fi
            rm -rf "$tmp" ;;
        *) echo "== $(basename "$f"): not a .cab or .Dnc, skipping" ;;
    esac
}

convert_folder() {
    local d="$1" f b base
    while IFS= read -r -u 3 f; do
        b=$(basename "$f"); b=${b%.*}
        # skip the small version when a large one exists
        case "$(lower "$b")" in
            *_s) base=${b%??}
                 if [ -n "$(find "$d" -maxdepth 1 -iname "${base}_l.*" | head -1)" ]; then continue; fi ;;
        esac
        convert_file "$f"
    done 3< <(find -L "$d" -maxdepth 1 -type f \( -iname '*.cab' -o -iname '*.dnc' \) | sort)
}

[ $# -ge 1 ] || { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//' >&2; exit 1; }

for arg in "$@"; do
    if [ -d "$arg" ]; then convert_folder "$arg"
    elif [ -f "$arg" ]; then convert_file "$arg"
    else echo "Can't find $arg" >&2; exit 1; fi
done
echo "Done. Pick a dancer in Pock > Widgets Manager > Dancer."
