# shellcheck shell=bash
# Popups. Zenity with a dark, terminal-style look; plain terminal output when
# there's no display or no zenity (or TEKU_NO_GUI=1).

TEKU_ACCENT='#3ddc97'
TEKU_CYAN='#4fd1ff'
TEKU_RED='#ff5c7a'
TEKU_DIM='#8b949e'

# Zenity 4 is libadwaita: ask for its dark scheme. GTK_THEME would replace
# libadwaita's stylesheet and leave the dialog transparent, so only zenity 3
# (GTK3) gets it.
export ADW_DEBUG_COLOR_SCHEME=${ADW_DEBUG_COLOR_SCHEME:-prefer-dark}
if command -v zenity >/dev/null && [[ $(zenity --version 2>/dev/null) == [0-3].* ]]; then
    export GTK_THEME=${GTK_THEME:-Adwaita:dark}
fi

ui_gui() {
    [[ -z ${TEKU_NO_GUI:-} ]] && command -v zenity >/dev/null &&
        [[ -n ${DISPLAY:-}${WAYLAND_DISPLAY:-} ]]
}

ui_esc() {
    local s=${1//&/&amp;}
    s=${s//</&lt;}
    printf '%s' "${s//>/&gt;}"
}

ui_plain() {
    sed -e 's/<[^>]*>//g' -e 's/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g' <<<"$1"
}

# Monospace header line: "▍TEKU // <section>" in the accent color.
ui_header() {
    local color=${2:-$TEKU_ACCENT}
    printf '<span font_family="monospace" weight="bold" foreground="%s">▍TEKU</span><span font_family="monospace" foreground="%s"> // %s</span>' \
        "$color" "$TEKU_DIM" "$(ui_esc "$1")"
}

# One aligned "key  value" row.
ui_row() {
    printf '\n<span font_family="monospace"><span foreground="%s">%-8s</span> <span foreground="%s">%s</span></span>' \
        "$TEKU_DIM" "$(ui_esc "$1")" "${3:-$TEKU_CYAN}" "$(ui_esc "$2")"
}

ui_confirm() {
    local text=$1 ok=${2:-Install}
    if [[ -n ${TEKU_YES:-} ]]; then return 0; fi
    if ui_gui; then
        zenity --question --title Teku --width 460 --ok-label "$ok" --cancel-label Cancel \
            --text "$text" 2>/dev/null
        return
    fi
    ui_plain "$text"
    [[ -t 0 ]] || return 1
    local reply
    read -rp "$ok? [y/N] " reply
    [[ $reply == [yY]* ]]
}

ui_info() {
    if ui_gui; then
        zenity --info --title Teku --width 460 --text "$1" 2>/dev/null
    else
        ui_plain "$1"
    fi
}

# ui_error TEXT [LOGFILE]
ui_error() {
    local text=$1 log=${2:-}
    if ! ui_gui; then
        ui_plain "$text" >&2
        [[ -s $log ]] && { echo "--- log: $log" >&2; tail -n 20 "$log" >&2; }
        return 0
    fi
    if [[ -s $log ]]; then
        local choice
        choice=$(zenity --error --title Teku --width 460 --text "$text" --extra-button "Show log" 2>/dev/null)
        if [[ $choice == "Show log" ]]; then
            zenity --text-info --title "Teku — log" --width 720 --height 440 \
                --font monospace --filename "$log" 2>/dev/null
        fi
    else
        zenity --error --title Teku --width 460 --text "$text" 2>/dev/null
    fi
}

# ui_progress TITLE LOGFILE CMD... — runs CMD, streams its output into a
# pulsing progress popup and LOGFILE, returns CMD's exit status.
ui_progress() {
    local title=$1 log=$2
    shift 2
    if ! ui_gui; then
        echo "» $title"
        "$@" 2>&1 | tee "$log"
        return "${PIPESTATUS[0]}"
    fi
    local status_file rc
    status_file=$(mktemp)
    {
        "$@" 2>&1 | tee "$log" | while IFS= read -r line; do
            line=${line//[<>&]/}
            [[ -n ${line// /} ]] && printf '# ▸ %s\n' "${line:0:72}"
        done
        echo "${PIPESTATUS[0]}" >"$status_file"
        echo 100
    } | zenity --progress --pulsate --auto-close --no-cancel --title "Teku — $title" \
        --width 520 --text "▸ starting…" 2>/dev/null
    rc=$(<"$status_file")
    rm -f "$status_file"
    return "${rc:-1}"
}

# ui_pick TITLE TEXT ITEM... — single-choice list, echoes the chosen item.
ui_pick() {
    local title=$1 text=$2
    shift 2
    if ui_gui; then
        zenity --list --title "$title" --text "$text" --width 520 --height 360 \
            --column Item "$@" 2>/dev/null
        return
    fi
    [[ -t 0 ]] || return 1
    local item
    PS3="$text "
    select item in "$@"; do [[ -n $item ]] && { echo "$item"; return 0; }; done
    return 1
}
