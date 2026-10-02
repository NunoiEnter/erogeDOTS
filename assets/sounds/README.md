# Title voice and session cues

`title.wav` is a generated Japanese female voice saying **“eroDOTS!”** (エロドッツ！), played once when the Romance VN title screen opens, including after a character change. The user requested a brighter, youthful anime-style delivery: higher pitch, quicker pace and an upbeat exclamation. It is generic synthetic speech, not a recording or imitation of a visual-novel actress. Generation used [edge-tts](https://github.com/rany2/edge-tts), voice `ja-JP-NanamiNeural`, pitch `+60Hz`, rate `+12%`, volume `+8%`, on 2026-10-02. Leading silence was trimmed, a 20 ms fade-in and 120 ms tail added, then converted to mono 24,000 Hz / 16-bit PCM WAV. The shipped file plays offline; no speech service is called from the desktop.

The three small WAV files here are original synthesized bell cues, **not character voice recordings**. `greeting.wav` plays on opening Exit, `confirm.wav` on choosing an action, and `cancel.wav` on returning. A suggested voice placeholder greeting is “See you next time.”

Replace them locally without editing the repository:

```text
~/.config/erogedots/sounds/title.ogg
~/.config/erogedots/sounds/greeting.ogg
~/.config/erogedots/sounds/confirm.ogg
~/.config/erogedots/sounds/cancel.ogg
```

WAV, MP3 and FLAC are also accepted. OGG takes priority. Your normal sound controls still apply. Playback uses mpv, with the fallback bells kept quiet.

Create an empty `~/.config/erogedots/sounds/mute` file to silence all VN voices and cues; remove it to enable them again. Replacing a local sound never requires a rebuild.

For a real visual novel reference, [Yuzusoft's official Senren＊Banka downloads](https://www.yuzu-soft.com/products/senren/download.html) offers heroine system voices for personal enjoyment. That page is a reference and personal download source; its recordings are not bundled or redistributed here. Choose your own greeting when ready. A separate UI cue reference is [oussamaben's menu selection chime](https://freesound.org/people/oussamaben/sounds/697241/); it is also not bundled.

The bundled cues use mono, 22,050 Hz, 16-bit PCM sine waves with an 8 ms attack and an exponential decay `exp(-7*t)`, amplitude 0.13. Greeting: E5 then C5 180 ms later, 800 ms total. Confirm: G5, 250 ms. Cancel: C5, 250 ms. No external audio samples were used.
