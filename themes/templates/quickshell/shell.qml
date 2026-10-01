// THESIS: A daily desktop framed like an early-2000s romance visual novel.
// OWN-WORLD: Cream stationery, pastel character colors, floral corners, serif names.
// STORY: Move between workspaces; open Menu for connections, sound, music and session.
// FIRST VIEWPORT: A 40px ribbon reveals animated top drawers; Super+S opens
// a VN title screen with bilingual choices and a character-load gallery.
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
    CalendarPopup { state: desktopState }
    VnTitleMenu { state: desktopState }
    VnTopDrawer { state: desktopState }
    IpcHandler {
        target: "calendar"
        function toggle(): void {
            desktopState.toggleCalendar(Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0]);
        }
        function close(): void { desktopState.calendarShown = false; }
    }
    IpcHandler {
        target: "quick-settings"
        function toggle(): void {
            desktopState.calendarShown = false;
            desktopState.menuScreen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.titlePage = "";
            desktopState.shown = !desktopState.shown;
        }
        function open(): void {
            desktopState.calendarShown = false;
            desktopState.menuScreen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.titlePage = "";
            desktopState.shown = true;
        }
        function page(name: string): void {
            desktopState.openSection(Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0], name);
        }
        function close(): void { desktopState.shown = false; }
    }
    IpcHandler {
        target: "terminal"
        function open(): void {
            if (desktopState.shown && !Theme.retro) desktopState.openTitleTerminal();
            else desktopState.launch(["ghostty"]);
        }
    }
    IpcHandler {
        target: "drawer"
        function open(page: string): void {
            const screen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.drawer.pin(screen, page, screen.width / 2);
        }
        function close(): void { desktopState.drawer.close(); }
    }
}
