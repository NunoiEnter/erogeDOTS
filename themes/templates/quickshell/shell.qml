// THESIS: A daily desktop framed like an early-2000s romance visual novel.
// OWN-WORLD: Cream stationery, pastel character colors, floral corners, serif names.
// STORY: Navigate every page by keyboard; choose a session action, then confirm it.
// FIRST VIEWPORT: A 40px ribbon reveals animated top drawers; Super+S opens
// a VN title screen with bilingual choices, a character gallery and session dialogue.
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
    VnSession { state: desktopState }
    IpcHandler {
        target: "theme-transition"
        function arrive(showTitle: bool): void {
            desktopState.themeEntering = true;
            desktopState.themeBusy = true;
            desktopState.menuScreen = Quickshell.screens.find(s => s.name === desktopState.niri.output) || Quickshell.screens[0];
            desktopState.titlePage = "";
            desktopState.shown = showTitle;
        }
        function ready(): bool { return !desktopState.shown || Theme.retro || desktopState.themeSceneReady; }
        function finish(): void {
            const entering = desktopState.themeEntering;
            desktopState.themeEntering = false;
            desktopState.themeBusy = false;
            if (entering && desktopState.shown && !Theme.retro) desktopState.playSessionSound("title");
        }
        function failed(): void { desktopState.themeEntering = false; desktopState.themeBusy = false; desktopState.themeError = "Theme change failed. Try again from a terminal to see the error."; }
    }
    IpcHandler {
        target: "session"
        function open(): void { desktopState.session(); }
        function confirm(action: string): void { desktopState.session(action); }
        function close(): void { desktopState.sessionShown = false; }
    }
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
