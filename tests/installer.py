#!/usr/bin/env python3
"""Exercise the installer worker with mocked privileged and Nix commands."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
STUB = '''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
name = Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ["CALL_LOG"], "a") as f:
    f.write(json.dumps([name, *args]) + "\\n")
if name == "id": print("moni")
elif name in ("hostnamectl", "hostname"): print("testhost")
elif name == "git":
    root = Path(os.environ["HOME"]) / "erogeDOTS"
    for name in ("flake.nix", "configuration.nix", "hosts/testhost/hardware-configuration.nix", "scripts/theme-switch"):
        sys.stdout.buffer.write(name.encode() + b"\\0")
elif name == "sudo" and args and not args[0].startswith("-"):
    os.execvp(args[0], args)
elif name == "nix" and os.environ.get("FAIL_CHECK") == "1": sys.exit(1)
'''


@unittest.skipUnless(Path('/etc/NIXOS').exists() or Path('/run/current-system/nixos-version').exists(), 'worker checks NixOS before proceeding')
class InstallerTests(unittest.TestCase):
    def fixture(self, directory):
        home = Path(directory)
        repo = home / 'erogeDOTS'
        (repo / 'hosts/testhost').mkdir(parents=True)
        (repo / 'scripts').mkdir()
        for name in ('flake.nix', 'configuration.nix', 'hosts/testhost/hardware-configuration.nix'):
            (repo / name).write_text('{}\n')
        (repo / 'target').mkdir()
        (repo / 'target/ignored-build').write_text('not transferred')
        shutil.copy2(ROOT / 'install.sh', repo / 'install.sh')
        binaries = home / 'bin'
        binaries.mkdir()
        for name in ('git', 'id', 'hostnamectl', 'hostname', 'sudo', 'nix', 'nixos-rebuild', 'nixos-generate-config', 'theme-picker'):
            path = binaries / name
            path.write_text(STUB)
            path.chmod(0o755)
        theme = repo / 'scripts/theme-switch'
        theme.write_text(STUB)
        theme.chmod(0o755)
        log = home / 'calls.jsonl'
        env = dict(os.environ, HOME=str(home), XDG_STATE_HOME=str(home / 'state'),
                   PATH=str(binaries) + ':' + os.environ['PATH'], CALL_LOG=str(log))
        return repo, env, log

    def test_plain_install_checks_builds_activates_and_cleans_source(self):
        with tempfile.TemporaryDirectory() as directory:
            repo, env, log = self.fixture(directory)
            result = subprocess.run(['bash', str(repo / 'install.sh'), '--plain'], env=env, capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            rebuilds = [call for call in calls if call[0] == 'nixos-rebuild']
            self.assertEqual([call[1] for call in rebuilds], ['build', 'switch'])
            stage = rebuilds[0][-1].removeprefix('path:').split('#')[0]
            self.assertNotEqual(stage, str(repo))
            self.assertFalse(Path(stage).exists(), 'temporary build source must be removed')
            self.assertIn('ALPHA 2.0 installed successfully', result.stdout)
            self.assertTrue((Path(directory) / 'state/erogedots/install.log').is_file())

    def test_failed_check_never_builds_or_activates(self):
        with tempfile.TemporaryDirectory() as directory:
            repo, env, log = self.fixture(directory)
            env['FAIL_CHECK'] = '1'
            result = subprocess.run(['bash', str(repo / 'install.sh'), '--plain'], env=env, capture_output=True, text=True, timeout=15)
            self.assertNotEqual(result.returncode, 0)
            calls = [json.loads(line) for line in log.read_text().splitlines()]
            self.assertFalse(any(call[0] == 'nixos-rebuild' for call in calls))

    def test_help_does_not_authenticate(self):
        with tempfile.TemporaryDirectory() as directory:
            repo, env, log = self.fixture(directory)
            result = subprocess.run(['bash', str(repo / 'install.sh'), '--help'], env=env, capture_output=True, text=True, timeout=5)
            self.assertEqual(result.returncode, 0)
            self.assertFalse(log.exists())


if __name__ == '__main__':
    unittest.main()
