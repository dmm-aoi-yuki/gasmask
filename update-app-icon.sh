#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
appicon_dir="$script_dir/Assets.xcassets/AppIcon.appiconset"
source_svg_name="app_icon_source.svg"
dest_svg_path="$appicon_dir/$source_svg_name"

if [ "$#" -gt 1 ]; then
	printf 'Usage: %s [path/to/icon.svg]\n' "$0" >&2
	exit 1
fi

if ! command -v qlmanage >/dev/null 2>&1; then
	printf 'qlmanage is required to render SVG files on macOS.\n' >&2
	exit 1
fi

source_svg_path="${1:-$dest_svg_path}"

if [ ! -f "$source_svg_path" ]; then
	printf 'SVG file not found: %s\n' "$source_svg_path" >&2
	exit 1
fi

if [ ! -d "$appicon_dir" ]; then
	printf 'AppIcon set not found: %s\n' "$appicon_dir" >&2
	exit 1
fi

tmpdir="$(mktemp -d)"
cleanup() {
	rm -rf "$tmpdir"
}
trap cleanup EXIT

wait_for_rendered_png() {
	local rendered_path="$1"
	local attempt=0

	while [ ! -f "$rendered_path" ]; do
		attempt=$((attempt + 1))
		if [ "$attempt" -ge 50 ]; then
			printf 'Timed out waiting for rendered icon: %s\n' "$rendered_path" >&2
			return 1
		fi
		/usr/bin/sleep 0.1
	done
}

if [ ! "$source_svg_path" -ef "$dest_svg_path" ]; then
	cp "$source_svg_path" "$dest_svg_path"
fi

render() {
	local size="$1"
	local output_name="$2"
	local render_dir="$tmpdir/render-$size-$$"
	local rendered_path="$render_dir/$source_svg_name.png"

	rm -rf "$render_dir"
	mkdir -p "$render_dir"
	qlmanage -t -s "$size" -o "$render_dir" "$dest_svg_path" >/dev/null
	wait_for_rendered_png "$rendered_path"
	mv "$rendered_path" "$appicon_dir/$output_name"
	printf 'Updated %s (%sx%s)\n' "$output_name" "$size" "$size"
}

render 16 icon_16x16.png
render 32 icon_16x16@2x.png
render 32 icon_32x32.png
render 64 icon_32x32@2x.png
render 128 icon_128x128.png
render 256 icon_128x128@2x.png
render 256 icon_256x256.png
render 512 icon_256x256@2x.png
render 512 icon_512x512.png
render 1024 icon_512x512@2x.png

printf 'App icon set updated from %s\n' "$source_svg_path"