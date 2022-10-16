
rofi_menu() {
    rofi -dmenu -theme ~/.config/rofi/styles/launcher.rasi -mesg " Screenshot aufnehmen"
}

selection() {
    echo -e "Screen\nWindow\nArea" | rofi_menu
}

current_date="$(date +%Y-%m-%d_%H:%M:%S)"
file_name=~/Bilder/Screenshots/${current_date}.png
type="$(selection)"
case ${type} in
    "Screen")
        maim ${file_name}
        ;;
    "Window")
        maim -i $(xdotool getactivewindow) ${file_name}
        ;;
    "Area")
        maim -s ${file_name}
        ;;
esac