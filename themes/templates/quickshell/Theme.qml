pragma Singleton
import QtQuick

QtObject {
    function translucent(color, alpha) { return Qt.rgba(color.r, color.g, color.b, alpha); }
    readonly property string style: "{{UI_STYLE}}"
    readonly property bool retro: style === "win98"
    readonly property string styleName: retro ? "Windows 98" : "Romance VN"
    readonly property color paper: "{{VN_PAPER}}"
    readonly property color ink: "{{VN_INK}}"
    readonly property color muted: "{{VN_MUTED}}"
    readonly property color accent: "{{VN_ACCENT}}"
    readonly property color tint: "{{VN_TINT}}"
    readonly property color line: "{{VN_LINE}}"
    readonly property string titleFont: "{{UI_TITLE_FONT}}"
    readonly property string bodyFont: "Noto Sans"
    readonly property string character: {{CHAR_NAME_JSON}}
    readonly property string fullName: {{CHAR_FULL_JSON}}
    readonly property string game: {{CHAR_GAME_JSON}}
    readonly property string wallpaper: {{WALLPAPER_PATH_JSON}}
    readonly property string characterId: {{THEME_ID_JSON}}
    readonly property var characters: {{CHARACTERS_JSON}}
}
