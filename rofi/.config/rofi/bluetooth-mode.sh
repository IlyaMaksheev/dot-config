#!/usr/bin/env bash
set -euo pipefail

print_row() {
  local label="$1" info="${2:-}"
  if [[ -n "$info" ]]; then
    printf '%s\0info\x1f%s\n' "$label" "$info"
  else
    printf '%s\n' "$label"
  fi
}

power_on() { bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; }
scan_on() { bluetoothctl show 2>/dev/null | grep -q 'Discovering: yes'; }
pairable_on() { bluetoothctl show 2>/dev/null | grep -q 'Pairable: yes'; }
discoverable_on() { bluetoothctl show 2>/dev/null | grep -q 'Discoverable: yes'; }
device_connected() { bluetoothctl info "$1" 2>/dev/null | grep -q 'Connected: yes'; }
device_paired() { bluetoothctl info "$1" 2>/dev/null | grep -q 'Paired: yes'; }
device_trusted() { bluetoothctl info "$1" 2>/dev/null | grep -q 'Trusted: yes'; }

main_menu() {
  if power_on; then
    bluetoothctl devices 2>/dev/null | while read -r _ mac name; do
      [[ -n "${mac:-}" && -n "${name:-}" ]] && print_row "$name" "device:$mac"
    done
    print_row '---------'
    print_row 'Power: on' 'toggle:power'
    if scan_on; then print_row 'Scan: on' 'toggle:scan'; else print_row 'Scan: off' 'toggle:scan'; fi
    if pairable_on; then print_row 'Pairable: on' 'toggle:pairable'; else print_row 'Pairable: off' 'toggle:pairable'; fi
    if discoverable_on; then print_row 'Discoverable: on' 'toggle:discoverable'; else print_row 'Discoverable: off' 'toggle:discoverable'; fi
    print_row 'Exit' 'exit'
  else
    print_row 'Power: off' 'toggle:power'
    print_row 'Exit' 'exit'
  fi
}

device_menu() {
  local mac="$1"
  local name
  name="$(bluetoothctl devices 2>/dev/null | awk -v mac="$mac" '$2 == mac { $1=""; $2=""; sub(/^  */, ""); print; exit }')"
  printf '\0prompt\x1f%s\n' "${name:-Bluetooth}"
  if device_connected "$mac"; then print_row 'Connected: yes' "device-action:$mac:connect"; else print_row 'Connected: no' "device-action:$mac:connect"; fi
  if device_paired "$mac"; then print_row 'Paired: yes' "device-action:$mac:pair"; else print_row 'Paired: no' "device-action:$mac:pair"; fi
  if device_trusted "$mac"; then print_row 'Trusted: yes' "device-action:$mac:trust"; else print_row 'Trusted: no' "device-action:$mac:trust"; fi
  print_row '---------'
  print_row 'Back' 'back'
  print_row 'Exit' 'exit'
}

info="${ROFI_INFO:-}"
case "$info" in
  device:*)
    device_menu "${info#device:}"
    ;;
  toggle:power)
    if power_on; then bluetoothctl power off >/dev/null; else rfkill unblock bluetooth 2>/dev/null || true; bluetoothctl power on >/dev/null; fi
    main_menu
    ;;
  toggle:scan)
    if scan_on; then bluetoothctl scan off >/dev/null; else bluetoothctl --timeout 5 scan on >/dev/null 2>&1 & fi
    main_menu
    ;;
  toggle:pairable)
    if pairable_on; then bluetoothctl pairable off >/dev/null; else bluetoothctl pairable on >/dev/null; fi
    main_menu
    ;;
  toggle:discoverable)
    if discoverable_on; then bluetoothctl discoverable off >/dev/null; else bluetoothctl discoverable on >/dev/null; fi
    main_menu
    ;;
  device-action:*:connect)
    mac="${info#device-action:}"; mac="${mac%:connect}"
    if device_connected "$mac"; then bluetoothctl disconnect "$mac" >/dev/null; else bluetoothctl connect "$mac" >/dev/null || true; fi
    device_menu "$mac"
    ;;
  device-action:*:pair)
    mac="${info#device-action:}"; mac="${mac%:pair}"
    if device_paired "$mac"; then bluetoothctl remove "$mac" >/dev/null; else bluetoothctl pair "$mac" >/dev/null || true; fi
    device_menu "$mac"
    ;;
  device-action:*:trust)
    mac="${info#device-action:}"; mac="${mac%:trust}"
    if device_trusted "$mac"; then bluetoothctl untrust "$mac" >/dev/null; else bluetoothctl trust "$mac" >/dev/null; fi
    device_menu "$mac"
    ;;
  back|'')
    main_menu
    ;;
  *)
    main_menu
    ;;
esac
