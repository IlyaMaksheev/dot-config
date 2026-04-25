#!/usr/bin/env bash
# Waybar custom module for dunst — outputs JSON for waybar consumption.
# Subscribes to dunst dbus signals and emits status on every change.

output() {
    local displayed waiting history dnd class icon tooltip alt

    displayed=$(dunstctl count displayed 2>/dev/null)
    waiting=$(dunstctl count waiting 2>/dev/null)
    history=$(dunstctl count history 2>/dev/null)
    dnd=$(dunstctl is-paused 2>/dev/null)

    total=$((displayed + waiting + history))

    if [[ "$dnd" == "true" ]]; then
        if (( total > 0 )); then
            alt="dnd-notification"
        else
            alt="dnd-none"
        fi
    else
        if (( total > 0 )); then
            alt="notification"
        else
            alt="none"
        fi
    fi

    if (( total > 0 )); then
        tooltip="$total notification(s): $displayed shown, $history in history"
    else
        tooltip="No notifications"
    fi

    if [[ "$dnd" == "true" ]]; then
        tooltip="$tooltip (DND on)"
    fi

    printf '{"alt":"%s","tooltip":"%s","class":"%s"}\n' \
        "$alt" "$tooltip" "$alt"
}

# Initial output
output

# Re-emit on any dunst dbus signal (notification added/closed/paused)
dbus-monitor --session "interface='org.dunstproject.cmd0'" 2>/dev/null | while read -r _; do
    # Debounce: skip rapid successive signals
    read -t 0.1 -r _ 2>/dev/null
    output
done
