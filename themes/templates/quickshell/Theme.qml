pragma Singleton
import QtQuick

QtObject {
    readonly property color paper: "{{VN_PAPER}}"
    readonly property color ink: "{{VN_INK}}"
    readonly property color muted: "{{VN_MUTED}}"
    readonly property color accent: "{{VN_ACCENT}}"
    readonly property color tint: "{{VN_TINT}}"
    readonly property color line: "{{VN_LINE}}"
    readonly property string titleFont: "Noto Serif JP"
    readonly property string bodyFont: "Noto Sans"
    readonly property string character: {{CHAR_NAME_JSON}}
    readonly property string fullName: {{CHAR_FULL_JSON}}
    readonly property string game: {{CHAR_GAME_JSON}}
    readonly property string wallpaper: {{WALLPAPER_PATH_JSON}}
}
