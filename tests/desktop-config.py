#!/usr/bin/env python3
"""Exercise editing and package boundaries without changing the live repository."""
import importlib.machinery
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader("desktop_config", str(ROOT / "scripts/desktop-config"))
spec = importlib.util.spec_from_loader(loader.name, loader)
config = importlib.util.module_from_spec(spec)
loader.exec_module(config)


class DesktopConfigTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="desktop-config-test-")
        self.root = Path(self.directory.name)
        config.ROOT = self.root
        config.CONFIG = self.root / "config"
        config.STATE = self.root / "state"
        config.FILES = {"nixos": self.root / "configuration.nix", "home": self.root / "home/moni.nix",
                        "niri": self.root / "themes/templates/niri/config.kdl"}
        config.PACKAGES = self.root / "home/desktop-packages.json"
        for path in config.FILES.values():
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / path.relative_to(self.root), path)
        config.PACKAGES.write_text("[]\n")
        shutil.copy2(ROOT / "flake.lock", self.root / "flake.lock")
        self.addCleanup(self.directory.cleanup)

    def test_valid_save_preserves_file_mode_and_backup(self):
        previous = config.dispatch({"operation": "read", "target": "home"})
        text = previous["text"] + "\n# edited through UI\n"
        result = config.dispatch({"operation": "save", "target": "home", "version": previous["version"], "text": text})
        self.assertEqual(config.FILES["home"].read_text(), text)
        self.assertEqual(result["version"], config.digest(text))
        self.assertEqual(next((config.STATE / "config-backups").iterdir()).read_text(), previous["text"])

    def test_invalid_nix_does_not_replace_source(self):
        previous = config.dispatch({"operation": "read", "target": "home"})
        with self.assertRaises(ValueError):
            config.dispatch({"operation": "save", "target": "home", "version": previous["version"], "text": "{ this is broken"})
        self.assertEqual(config.FILES["home"].read_text(), previous["text"])

    def test_external_edits_before_and_during_validation_win(self):
        previous = config.dispatch({"operation": "read", "target": "home"})
        config.FILES["home"].write_text("external edit")
        request = {"operation": "save", "target": "home", "version": previous["version"], "text": previous["text"]}
        with self.assertRaises(ValueError):
            config.dispatch(request)
        config.FILES["home"].write_text(previous["text"])
        with patch.object(config, "validate", side_effect=lambda *_: config.FILES["home"].write_text("new external edit")):
            with self.assertRaises(ValueError):
                config.dispatch(request)
        self.assertEqual(config.FILES["home"].read_text(), "new external edit")

    def test_package_names_are_arguments_not_expressions(self):
        for name in ("hello; rm", 'hello\"', "../file", "hello + pkgs.vim", ""):
            with self.assertRaises(ValueError):
                config.dispatch({"operation": "add", "package": name})
        with patch.object(config, "run", return_value="kate") as command:
            config.dispatch({"operation": "add", "package": "kdePackages.kate"})
            self.assertIn("p.kdePackages.kate", command.call_args[0][0][-1])
        self.assertEqual(config.packages(), ["kdePackages.kate"])
        config.dispatch({"operation": "remove", "package": "kdePackages.kate"})
        self.assertEqual(config.packages(), [])

    def test_editor_target_and_symlinks_are_bounded(self):
        with self.assertRaises(ValueError):
            config.dispatch({"operation": "read", "target": "../../etc/passwd"})
        config.FILES["home"].unlink()
        config.FILES["home"].symlink_to(ROOT / "home/moni.nix")
        with self.assertRaises(ValueError):
            config.dispatch({"operation": "read", "target": "home"})

    def test_niri_changes_validate_and_keep_unrelated_bindings(self):
        config.CONFIG.mkdir()
        shutil.copytree(Path.home() / ".config/theme", config.CONFIG / "theme", ignore=shutil.ignore_patterns("cache"))
        (self.root / "scripts").mkdir()
        shutil.copy2(ROOT / "scripts/theme-switch", self.root / "scripts/theme-switch")
        for theme in (ROOT / "themes").glob("*/theme.conf"):
            shutil.copytree(theme.parent, self.root / "themes" / theme.parent.name)
        before = config.FILES["niri"].read_text()
        config.dispatch({"operation": "niri-settings", "gaps": 12, "focusWidth": 3, "columnWidth": 60})
        after = config.FILES["niri"].read_text()
        self.assertEqual(config.niri_settings(after), {"gaps": 12, "focusWidth": 3, "columnWidth": 60})
        self.assertEqual(after.count("Mod+"), before.count("Mod+"))
        with self.assertRaises(ValueError):
            config.dispatch({"operation": "niri-settings", "gaps": -1, "focusWidth": 3, "columnWidth": 60})


if __name__ == "__main__":
    unittest.main()
