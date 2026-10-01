// THESIS: A daily desktop framed like an early-2000s romance visual novel.
// OWN-WORLD: Cream stationery, pastel character colors, floral corners, serif names.
// STORY: Move between workspaces; open Menu for connections, sound, music and session.
// FIRST VIEWPORT: A 52px chapter ribbon; Menu opens an illustrated dialogue frame
// near the bottom, with a character nameplate, wallpaper and keyboard controls.
// FORM: User-pinned romance VN; seed 4a141650 yields to the confirmed brief.
// FINISH: unreviewed and undocumented is unfinished; this build ends with the finish review, the verdict, DESIGN.md, and every shipping raster carrying its provenance
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    ShellState { id: desktopState }
    Variants {
        model: Quickshell.screens
        ChapterBar {
            required property var modelData
            screen: modelData
            state: desktopState
        }
    }
    SettingsMenu { state: desktopState }
    IpcHandler {
        target: "quick-settings"
        function toggle(): void {
            desktopState.menuScreen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.shown = !desktopState.shown;
        }
        function open(): void {
            desktopState.menuScreen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.shown = true;
        }
        function close(): void { desktopState.shown = false; }
    }
}
