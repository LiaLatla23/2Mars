# Test report · 2Mars V5.1

## Available test assets

The V5 project includes automated test scenes and scripts:

- `Game-versions/V5/tests/Compile.tscn` and `compile.gd` — script compilation checks.
- `Game-versions/V5/tests/Bot.tscn` and `bot.gd` — automated interaction with game flows and gameplay systems.
- `Game-versions/V5/tests/Layout.tscn` and `layout.gd` — interface/layout checks.

The bot is intended to exercise the game using its normal input and rules. The presence of these files documents available test coverage; it does not establish that the latest V5.1 build passed a fresh run.

## Reproduce the checks

Run from the repository root with Godot 4.7 available on your PATH:

```bash
godot --headless --path Game-versions/V5 res://tests/Compile.tscn
godot --headless --fixed-fps 60 --path Game-versions/V5 res://tests/Bot.tscn
godot --headless --path Game-versions/V5 res://tests/Layout.tscn
```

Preserve the actual console output, Godot version, operating system and commit hash when reporting a test result.

## Evidence status

Team members have manually played complete game sessions. These are internal playtests, not external user testing or a formal educational-impact evaluation.

No new automated test execution is claimed in this documentation update. A successful result should be added only after running the commands and recording the actual output.

## Limits

- Automated tests are regression checks written by the development team, not independent QA certification.
- Internal manual playtesting does not establish usability for external students.
- No measured educational outcomes or controlled classroom evaluation are documented.
- Controller support should be treated as unverified unless tested on the intended controller and platform.
