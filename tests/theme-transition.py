#!/usr/bin/env python3
"""Real theme script, isolated configs and fake desktop IPC; never restart the session."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
import wave

ROOT = Path(__file__).resolve().parents[1]
MOCK = '''#!/usr/bin/env python
import json, os, sys
from pathlib import Path
args = sys.argv[1:]
root = Path(os.environ["MOCK_STATE"])
with (root / "calls").open("a") as log:
    log.write(json.dumps(args) + "\\n")
if args[0] == "list":
    print("[]")
elif args[0] == "-d":
    if "theme-curtain.qml" not in args[-1] and os.environ.get("MOCK_FAIL") == "startup":
        sys.exit(1)
elif "call" in args:
    method = args[args.index("call") + 2]
    if method in ("arrive", "ready", "covered"):
        counter = root / method
        count = int(counter.read_text()) if counter.exists() else 0
        counter.write_text(str(count + 1))
        if method == "arrive":
            sys.exit(0 if count >= 1 else 1)
        print("true" if count >= 1 else "false")
'''


class ThemeTransitionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="vn-transition-")
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        binaries = self.directory / "bin"
        binaries.mkdir()
        for name, source in {"quickshell": MOCK, "pgrep": "#!/bin/sh\nexit 1\n", "awww": "#!/bin/sh\nexit 0\n"}.items():
            path = binaries / name
            path.write_text(source)
            path.chmod(0o755)
        self.env = dict(os.environ, PATH=str(binaries) + ":" + os.environ["PATH"],
                        MOCK_STATE=str(self.directory), EROGEDOTS_ROOT=str(ROOT),
                        EROGEDOTS_CONFIG_HOME=str(self.directory / "config"),
                        XDG_CACHE_HOME=str(self.directory / "cache"), EROGEDOTS_NO_RESTART="0")

    def run_switch(self, *args):
        return subprocess.run([str(ROOT / "scripts/theme-switch"), *args],
                              env=self.env, capture_output=True, text=True, timeout=30)

    def methods(self):
        calls = [json.loads(line) for line in (self.directory / "calls").read_text().splitlines()]
        return [call[call.index("call") + 2:] for call in calls if "call" in call]

    def test_title_is_ready_before_reveal(self):
        result = self.run_switch("nanami", "--show-menu")
        self.assertEqual(result.returncode, 0, result.stderr)
        methods = self.methods()
        names = [entry[0] for entry in methods]
        self.assertGreaterEqual(names.count("covered"), 2)
        self.assertGreaterEqual(names.count("arrive"), 2)
        self.assertGreaterEqual(names.count("ready"), 2)
        self.assertIn(["arrive", "true"], methods)
        self.assertLess(names.index("covered"), names.index("arrive"))
        self.assertLess(names.index("ready"), names.index("release"))
        self.assertLess(names.index("release"), names.index("finish"))
        self.assertNotIn("page", names)

    def test_cli_returns_to_desktop_and_lock_is_reusable(self):
        for _ in range(2):
            result = self.run_switch("nanami")
            self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(["arrive", "false"], self.methods())

    def test_style_switch_returns_to_title(self):
        result = self.run_switch("style", "win98", "--show-menu")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(["arrive", "true"], self.methods())
        self.assertEqual((self.directory / "config/theme/style").read_text().strip(), "win98")

    def test_failed_startup_releases_curtain(self):
        self.env["MOCK_FAIL"] = "startup"
        result = self.run_switch("nanami", "--show-menu")
        self.assertNotEqual(result.returncode, 0)
        names = [entry[0] for entry in self.methods()]
        self.assertIn("failed", names)
        self.assertIn("release", names)
        self.assertNotIn("finish", names)


class VnSoundTests(unittest.TestCase):
    def test_title_file_is_short_offline_pcm(self):
        with wave.open(str(ROOT / "assets/sounds/title.wav")) as sound:
            self.assertEqual(sound.getnchannels(), 1)
            self.assertEqual(sound.getsampwidth(), 2)
            self.assertEqual(sound.getframerate(), 24000)
            self.assertTrue(0.3 < sound.getnframes() / sound.getframerate() < 4)

    def test_local_override_and_mute(self):
        with tempfile.TemporaryDirectory(prefix="vn-sound-") as directory:
            root = Path(directory)
            (root / "bin").mkdir()
            mpv = root / "bin/mpv"
            mpv.write_text('#!/bin/sh\nprintf "%s\\n" "$@"\n')
            mpv.chmod(0o755)
            env = dict(os.environ, PATH=str(root / "bin") + ":" + os.environ["PATH"],
                       XDG_CONFIG_HOME=str(root / "config"), EROGEDOTS_ROOT=str(ROOT))
            command = [str(ROOT / "scripts/vn-sound"), "title"]
            result = subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertIn(str(ROOT / "assets/sounds/title.wav"), result.stdout)
            sounds = root / "config/erogedots/sounds"
            sounds.mkdir(parents=True)
            (sounds / "title.wav").touch()
            (sounds / "title.ogg").touch()
            result = subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertIn(str(sounds / "title.ogg"), result.stdout)
            (sounds / "mute").touch()
            result = subprocess.run(command, env=env, check=True, capture_output=True, text=True)
            self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
