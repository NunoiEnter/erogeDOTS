# Terminal Larp Kit

Look like a hacker. Feel like a hacker. Be a cat chasing a mouse.

## Audio Visualizer

| Command | What | Usage |
|---------|------|-------|
| `cave` | Audio spectrum bars | Run while playing music — reacts to system audio |
| `cave &` | Background visualizer | Keeps running while you do other stuff |

## Matrix & Rain

| Command | What | Usage |
|---------|------|-------|
| `cmx` | Matrix digital rain | Classic green/red rain in terminal color |
| `cmx -s 1` | Slow matrix | Less chaotic, more cinematic |

## Hacker Showcase

| Command | What | Usage |
|---------|------|-------|
| `hwood` | Hollywood hacker | Splits terminal into 6+ panes: code, logs, network, etc. |
| `hwood` then `q` | Quit | Press q to exit |

## ASCII Art

| Command | What | Usage |
|---------|------|-------|
| `aqua` | ASCII aquarium | Fish swimming in your terminal |
| `treeg` | Growing bonsai | Watch an ASCII tree grow |
| `shout` | Big text rainbow | `echo "hello" \| figlet \| lolcat` |
| `figlet "text"` | Big ASCII text | Large letters from any text |
| `fortune \| cowsay` | Random quote from cow | Classic |
| `fortune \| neo-cowsay -f dragon` | Quote from dragon | Use `-f` to pick character |
| `rainbows` | Fortune + cow + rainbow | All combined |

## Pokémon

| Command | What | Usage |
|---------|------|-------|
| `pkmn` | Random Pokémon sprite | Rainbow colored, changes each run |

## Desktop Pets

| Command | What | Usage |
|---------|------|-------|
| `catgo` | Oneko cat | Cat chases your mouse cursor on screen |
| `catgo &` | Background cat | Keep cat running while you work |

## Clocks

| Command | What | Usage |
|---------|------|-------|
| `ttyclock` | TTY digital clock | Theme-colored clock, full screen terminal |
| `ttyclock -C red` | Red clock | Override color |

## Pranks

| Command | What | Usage |
|---------|------|-------|
| `train` | Steam locomotive | Train runs across terminal when you mistype `ls` |
| `sl` | Same thing | The OG name |

## Combo: Full Larp

```bash
# Terminal looks like a hacking scene
clear && hwood

# Chill mode — matrix + cat on screen
cmx &
catgo &

# Music visualizer vibes
cave &

# All at once
cmx & catgo & cave &
```

## Mini Terminal

`Mod+Shift+Return` — small floating terminal bottom-left.
Keep it running `ttyclock` or `cave` as a widget.
