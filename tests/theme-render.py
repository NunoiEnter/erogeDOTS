#!/usr/bin/env python3
"""Exercise real theme rendering into temporary directories, without reloading the desktop."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import tomllib
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ThemeRenderTests(unittest.TestCase):
    def render(self, name, config, root=ROOT):
        env = dict(os.environ, EROGEDOTS_ROOT=str(root),
                   EROGEDOTS_CONFIG_HOME=str(config), EROGEDOTS_NO_RESTART="1")
        subprocess.run([str(ROOT / "scripts/theme-switch"), name], env=env,
                       check=True, stdout=subprocess.DEVNULL)
        files = [p for p in config.rglob("*") if p.is_file()]
        self.assertTrue(files)
        for path in files:
            self.assertNotRegex(path.read_text(), r"\{\{[A-Z0-9_]+\}\}", str(path))
        self.assertEqual((config / "theme/active").read_text().strip(), name)
        self.assertTrue((config / "quickshell/NiriState.qml").is_file())
        self.assertIn("ChapterBar 1.0 ChapterBar.qml", (config / "quickshell/qmldir").read_text())
        json.loads((config / "swaync/config.json").read_text())
        layout = (config / "wlogout/layout").read_text().strip()
        buttons = []
        decoder = json.JSONDecoder()
        while layout:
            button, end = decoder.raw_decode(layout)
            self.assertIsInstance(button, dict)
            buttons.append(button)
            layout = layout[end:].lstrip()
        self.assertEqual(len(buttons), 5)
        for command in (["niri", "validate", "--config", str(config / "niri/config.kdl")],
                        ["fuzzel", "--config=" + str(config / "fuzzel/fuzzel.ini"), "--check-config"]):
            subprocess.run(command, check=True, capture_output=True)

    def test_all_shipped_themes(self):
        with tempfile.TemporaryDirectory(prefix="vn-themes-") as directory:
            for theme in sorted((ROOT / "themes").glob("*/theme.conf")):
                with self.subTest(theme=theme.parent.name):
                    self.render(theme.parent.name, Path(directory) / theme.parent.name)

    def test_legacy_theme_and_quoted_metadata(self):
        # A legacy theme has no vn_* keys. QML must still load its literal metadata.
        with tempfile.TemporaryDirectory(prefix="vn-legacy-") as directory:
            root = Path(directory)
            (root / "themes/legacy").mkdir(parents=True)
            (root / "themes/templates").symlink_to(ROOT / "themes/templates", target_is_directory=True)
            content = (ROOT / "themes/harumi/theme.conf").read_text()
            content = "\n".join(line for line in content.splitlines() if not line.startswith("vn_"))
            name = 'Ena "Rose" \\ Notes'
            content = content.replace('char_name = "陽見恵凪"', 'char_name = ' + json.dumps(name))
            (root / "themes/legacy/theme.conf").write_text(content)
            self.render("legacy", root / "config", root)
            theme = (root / "config/quickshell/Theme.qml").read_text()
            value = next(line.split(": ", 1)[1] for line in theme.splitlines() if "string character:" in line)
            self.assertEqual(json.loads(value), name)
            self.assertIn('color paper: "#fff9f0"', theme)

    def test_interface_text_contrast(self):
        def luminance(color):
            channels = [int(color[i:i + 2], 16) / 255 for i in (1, 3, 5)]
            linear = [x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4 for x in channels]
            return sum(x * y for x, y in zip(linear, (0.2126, 0.7152, 0.0722)))
        for theme in (ROOT / "themes").glob("*/theme.conf"):
            data = tomllib.loads(theme.read_text())["colors"]
            for foreground in ("vn_ink", "vn_muted", "vn_accent"):
                ratio = (luminance(data["vn_paper"]) + 0.05) / (luminance(data[foreground]) + 0.05)
                self.assertGreaterEqual(ratio, 4.5, f"{theme.parent.name}: {foreground}")


if __name__ == "__main__":
    unittest.main()
