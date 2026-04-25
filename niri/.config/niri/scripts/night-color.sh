#!/usr/bin/env bash
#
# Night Color toggle script for wl-gammarelay-rs
# Controls display color temperature via DBus with smooth transitions
#
# Usage:
#   night-color.sh toggle   - Smoothly toggle between day/night mode
#   night-color.sh on       - Smoothly transition to night mode (warm)
#   night-color.sh off      - Smoothly transition to day mode (neutral)
#   night-color.sh status   - Print "true" or "false" (for swaync toggle button)
#   night-color.sh auto     - Smoothly adjust temperature based on sun position
#

STATE_FILE="/tmp/night-color-state"
LOCK_FILE="/tmp/night-color-transition.lock"
NIGHT_TEMP=4000
DAY_TEMP=6500

# Transition settings
TOGGLE_STEPS=50          # Number of steps for manual toggle
TOGGLE_SLEEP=0.04        # Sleep between steps (seconds) — total ~2s

# Tashkent, Uzbekistan (GMT+5)
LATITUDE=41.3
LONGITUDE=69.3

DBUS_DEST="rs.wl-gammarelay"
DBUS_PATH="/"
DBUS_IFACE="rs.wl.gammarelay"

get_temperature() {
    busctl --user get-property "$DBUS_DEST" "$DBUS_PATH" "$DBUS_IFACE" Temperature 2>/dev/null | awk '{print $2}'
}

set_temperature() {
    busctl --user set-property "$DBUS_DEST" "$DBUS_PATH" "$DBUS_IFACE" Temperature q "$1"
}

is_night_mode() {
    local temp
    temp=$(get_temperature)
    if [[ -z "$temp" ]]; then
        [[ -f "$STATE_FILE" ]] && cat "$STATE_FILE" || echo "false"
        return
    fi
    # Use midpoint as threshold
    local midpoint=$(( (DAY_TEMP + NIGHT_TEMP) / 2 ))
    if (( temp < midpoint )); then
        echo "true"
    else
        echo "false"
    fi
}

save_state() {
    echo "$1" > "$STATE_FILE"
}

# Acquire a lock so concurrent transitions don't fight.
# If another transition is running, kill it and take over.
acquire_lock() {
    if [[ -f "$LOCK_FILE" ]]; then
        local old_pid
        old_pid=$(cat "$LOCK_FILE" 2>/dev/null)
        if [[ -n "$old_pid" ]] && kill -0 "$old_pid" 2>/dev/null; then
            kill "$old_pid" 2>/dev/null
            wait "$old_pid" 2>/dev/null
        fi
    fi
    echo $$ > "$LOCK_FILE"
}

release_lock() {
    local lock_pid
    lock_pid=$(cat "$LOCK_FILE" 2>/dev/null)
    if [[ "$lock_pid" == "$$" ]]; then
        rm -f "$LOCK_FILE"
    fi
}

trap release_lock EXIT

# Smoothly transition from current temperature to target
# Args: target_temp [steps] [sleep_interval]
smooth_transition() {
    local target="$1"
    local steps="${2:-$TOGGLE_STEPS}"
    local sleep_time="${3:-$TOGGLE_SLEEP}"

    local current
    current=$(get_temperature)
    [[ -z "$current" ]] && current=$DAY_TEMP

    # Already at target (within rounding)
    local diff=$(( target - current ))
    if (( diff < 0 )); then diff=$(( -diff )); fi
    if (( diff <= 10 )); then
        set_temperature "$target"
        return
    fi

    acquire_lock

    local i
    for (( i = 1; i <= steps; i++ )); do
        # Linear interpolation: current + (target - current) * i / steps
        local temp=$(( current + (target - current) * i / steps ))
        set_temperature "$temp"
        sleep "$sleep_time"
    done

    # Ensure we land exactly on target
    set_temperature "$target"
    release_lock
}

enable_night() {
    save_state "true"
    smooth_transition "$NIGHT_TEMP" "$@"
}

disable_night() {
    save_state "false"
    smooth_transition "$DAY_TEMP" "$@"
}

# Calculate target temperature based on sun position.
# Returns a temperature value between NIGHT_TEMP and DAY_TEMP
# using a smooth gradient during twilight periods.
# Uses python3 with only stdlib (math, datetime).
get_sun_target_temp() {
    python3 - "$LATITUDE" "$LONGITUDE" "$DAY_TEMP" "$NIGHT_TEMP" <<'PYEOF'
import sys, math, datetime

def sun_times(lat, lon, date):
    """NOAA algorithm. Returns (sunrise_utc_h, sunset_utc_h) in fractional hours UTC."""
    N = date.timetuple().tm_yday
    gamma = (2 * math.pi / 365) * (N - 1)
    eqtime = 229.18 * (0.000075 + 0.001868 * math.cos(gamma)
             - 0.032077 * math.sin(gamma)
             - 0.014615 * math.cos(2 * gamma)
             - 0.040849 * math.sin(2 * gamma))
    decl = (0.006918 - 0.399912 * math.cos(gamma)
            + 0.070257 * math.sin(gamma)
            - 0.006758 * math.cos(2 * gamma)
            + 0.000907 * math.sin(2 * gamma)
            - 0.002697 * math.cos(3 * gamma)
            + 0.00148 * math.sin(3 * gamma))
    lat_rad = math.radians(lat)
    cos_ha = (math.cos(math.radians(90.833)) / (math.cos(lat_rad) * math.cos(decl))
              - math.tan(lat_rad) * math.tan(decl))
    cos_ha = max(-1, min(1, cos_ha))
    ha = math.degrees(math.acos(cos_ha))
    sunrise_utc = 720 - 4 * (lon + ha) - eqtime
    sunset_utc = 720 - 4 * (lon - ha) - eqtime
    return sunrise_utc / 60.0, sunset_utc / 60.0

lat = float(sys.argv[1])
lon = float(sys.argv[2])
day_temp = int(sys.argv[3])
night_temp = int(sys.argv[4])

# Twilight transition duration in hours (45 minutes)
TWILIGHT_H = 0.75

now_utc = datetime.datetime.now(datetime.timezone.utc)
today = now_utc.date()
sunrise_h, sunset_h = sun_times(lat, lon, today)
current_h = now_utc.hour + now_utc.minute / 60.0 + now_utc.second / 3600.0

# Calculate a blend factor: 0.0 = full night, 1.0 = full day
# Smooth transition during twilight windows around sunrise/sunset

def smoothstep(t):
    """Smooth Hermite interpolation (ease-in-out) for t in [0,1]."""
    t = max(0.0, min(1.0, t))
    return t * t * (3 - 2 * t)

if current_h < sunrise_h - TWILIGHT_H:
    # Deep night (before dawn twilight)
    factor = 0.0
elif current_h < sunrise_h + TWILIGHT_H:
    # Dawn twilight: smooth transition night -> day
    t = (current_h - (sunrise_h - TWILIGHT_H)) / (2 * TWILIGHT_H)
    factor = smoothstep(t)
elif current_h < sunset_h - TWILIGHT_H:
    # Full day
    factor = 1.0
elif current_h < sunset_h + TWILIGHT_H:
    # Dusk twilight: smooth transition day -> night
    t = (current_h - (sunset_h - TWILIGHT_H)) / (2 * TWILIGHT_H)
    factor = 1.0 - smoothstep(t)
else:
    # Deep night (after dusk twilight)
    factor = 0.0

# Interpolate temperature
temp = int(night_temp + (day_temp - night_temp) * factor)
# Clamp to valid range
temp = max(min(night_temp, day_temp), min(max(night_temp, day_temp), temp))
print(temp)
PYEOF
}

case "${1:-toggle}" in
    toggle)
        if [[ "$(is_night_mode)" == "true" ]]; then
            disable_night
        else
            enable_night
        fi
        ;;
    on)
        enable_night
        ;;
    off)
        disable_night
        ;;
    status)
        is_night_mode
        ;;
    auto)
        target=$(get_sun_target_temp)
        current=$(get_temperature)
        [[ -z "$current" ]] && current=$DAY_TEMP
        diff=$(( target - current ))
        if (( diff < 0 )); then diff=$(( -diff )); fi
        if (( diff > 10 )); then
            # Use fewer steps for auto (called every 15min, gradual by nature)
            smooth_transition "$target" 30 0.05
        fi
        # Update state file based on resulting temperature
        local_temp=$(get_temperature)
        midpoint=$(( (DAY_TEMP + NIGHT_TEMP) / 2 ))
        if (( local_temp < midpoint )); then
            save_state "true"
        else
            save_state "false"
        fi
        ;;
    *)
        echo "Usage: $0 {toggle|on|off|status|auto}"
        exit 1
        ;;
esac
