#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
theme_src="$script_dir/theme/gruvbox-breeze"
config_src="$script_dir/config/zz-gruvbox.conf"
xsetup_src="$script_dir/scripts/xsetup"

theme_dst="/usr/share/sddm/themes/gruvbox-breeze"
config_dst="/etc/sddm.conf.d/zz-gruvbox.conf"
xsetup_dst="/usr/local/bin/sddm-gruvbox-xsetup"
old_config_dst="/etc/sddm.conf.d/99-gruvbox.conf"

if [[ ! -d "$theme_src" ]]; then
  echo "Missing theme source: $theme_src" >&2
  exit 1
fi

if [[ ! -f "$config_src" ]]; then
  echo "Missing config source: $config_src" >&2
  exit 1
fi

if [[ ! -f "$xsetup_src" ]]; then
  echo "Missing Xsetup source: $xsetup_src" >&2
  exit 1
fi

install -d /usr/share/sddm/themes /etc/sddm.conf.d /usr/local/bin

# Remove previous symlink/copy. rm -rf on a symlink removes the symlink itself,
# not the target in ~/dot-config.
rm -rf "$theme_dst"
rm -f "$config_dst" "$old_config_dst"

cp -a "$theme_src" "$theme_dst"
install -m 0644 "$config_src" "$config_dst"
install -m 0755 "$xsetup_src" "$xsetup_dst"

# Ensure root-owned, world-readable system files. This avoids depending on the
# sddm greeter user being able to traverse /home/korvin.
chown -R root:root "$theme_dst"
chmod -R a+rX "$theme_dst"
chown root:root "$config_dst" "$xsetup_dst"
chmod 0644 "$config_dst"
chmod 0755 "$xsetup_dst"

echo "Installed SDDM theme: $theme_dst"
echo "Installed SDDM config: $config_dst"
echo "Installed SDDM Xsetup: $xsetup_dst"
echo
find /etc/sddm.conf.d -maxdepth 1 \( -type f -o -type l \) | sort | xargs -r grep -Hn '^Current=' || true
