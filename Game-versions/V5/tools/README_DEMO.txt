# V5 screenshot and demo capture utility

The V5 project includes a scripted capture scene at `tools/Shots.tscn`. It opens the real game UI, drives selected screens and saves PNG captures. It uses a dedicated test save path and is intended for development evidence capture.

Run from the `Game-versions/V5` directory:

```bash
godot --path . res://tools/Shots.tscn -- --screen=ops --out=user://shots --es --zone=life
```

Useful options:

- `--screen=menu` or another screen name selects the starting screen.
- `--out=PATH` sets the output directory.
- `--es` selects Spanish.
- `--zone=life` selects an exploration zone.
- `--full` loads the scripted full rover configuration.
- `--progress` adds sample progression and achievements for UI captures.
- `--name=PREFIX` sets the output filename prefix.
- `--wait=FRAMES` sets the initial wait before capture.
- `--steps=shot,wait:30,shot` defines a comma-separated capture sequence.

Example:

```bash
godot --path . res://tools/Shots.tscn -- --screen=ops --out=user://shots --es --full --progress --steps=shot,wait:60,shot
```

The script can also navigate screens, trigger methods and simulate input. See `shots.gd` for the supported step syntax.

These screenshots document interface states; they are not a substitute for interactive testing or a formal usability study.
