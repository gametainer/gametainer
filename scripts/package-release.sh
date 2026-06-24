#!/usr/bin/env bash
set -euo pipefail

target="${1:?usage: package-release.sh <target>}"
version="${GAMETAINER_VERSION:-dev}"
profile="${PROFILE:-release}"
target_root="${CARGO_TARGET_DIR:-target}"

case "$target" in
  *windows*) exe=".exe" ;;
  *) exe="" ;;
esac

bin_dir="$target_root/$target/$profile"
if [[ ! -d "$bin_dir" ]]; then
  bin_dir="$target_root/$profile"
fi

for binary in gametainer gamer; do
  if [[ ! -f "$bin_dir/$binary$exe" ]]; then
    echo "missing built binary: $bin_dir/$binary$exe" >&2
    exit 1
  fi
done

out_dir="${OUT_DIR:-dist}"
package="gametainer-$version-$target"
stage_dir="$out_dir/stage/$package"
archive="$out_dir/$package.tar.gz"

rm -rf "$stage_dir"
mkdir -p "$stage_dir"

cp "$bin_dir/gametainer$exe" "$stage_dir/"
cp "$bin_dir/gamer$exe" "$stage_dir/"
cp README.md "$stage_dir/"

tar -C "$out_dir/stage" -czf "$archive" "$package"
if command -v shasum >/dev/null 2>&1; then
  shasum -a 256 "$archive" > "$archive.sha256"
else
  sha256sum "$archive" > "$archive.sha256"
fi

echo "$archive"
