# Test report · 2Mars V4

## Scope

V4 includes an automated test scene and a test bot that interacts with the actual game flow. The bot uses a dedicated save path (`user://2mars_bot_save.json`) so it does not overwrite normal player saves. It supports English and Spanish runs, a quick full-mission route, V4-specific checks, and optional screenshot capture when run with a display.

The repository also records that team members manually played complete game sessions. These were internal playtests, not external user testing or a formal educational-impact evaluation.

## Reproduce the checks

Run commands from the repository root with Godot 4.7 available on your PATH.

```bash
# Load/compile scripts through the project's compile test
godot --headless --path Game-versions/V4 res://tests/Compile.tscn

# Run the complete automated bot suite
godot --headless --fixed-fps 60 --path Game-versions/V4 res://tests/Bot.tscn

# Run the complete bot in Spanish
godot --headless --fixed-fps 60 --path Game-versions/V4 res://tests/Bot.tscn -- --es

# Run the shorter full-mission route
godot --headless --fixed-fps 60 --path Game-versions/V4 res://tests/Bot.tscn -- --quick

# Run the quick route plus V4-specific checks
godot --headless --fixed-fps 60 --path Game-versions/V4 res://tests/Bot.tscn -- --quick --v4
```

The bot prints a final line in this form:

```text
BOT SUMMARY: <number> checks; <number> failures
```

The compile test prints:

```text
COMPILE SUMMARY: <number> scripts; <number> failures
```

A successful run should exit with code 0 and report zero failures. Preserve the actual console output, Godot version, operating system and commit hash when recording a test result.

## Test coverage visible in the bot

The current `Game-versions/V4/tests/bot.gd` contains checks for:

- Engineering catalogue size and component availability.
- Rover mass, cost, power generation, energy storage and data storage.
- Compatibility blockers, limitations, risks and readiness recommendations.
- Mission progression and a complete mission route.
- Multiple rover builds and exploration zones.
- Save/load behaviour and edge cases.
- Sandbox mode and local cooperative mode.
- Language-related flows and interface screens.
- V4-specific progression, inventory, Mars base and 3D rover presentation.

This list describes areas covered by the test code; it is not a claim that a fresh test run was executed as part of this documentation update.

## Test evidence log

No new automated test execution was performed as part of this documentation change. Add a dated entry only after running the commands above:

| Date | Commit | Godot version / OS | Command | Checks or scripts | Failures | Log |
|---|---|---|---|---:|---:|---|
| _Add after execution_ | — | — | — | — | — | — |

## Known limits

- Automated tests are regression checks written by the development team; they are not independent QA certification.
- Internal manual playtesting does not establish usability for external students.
- No measured educational outcomes or controlled classroom evaluation are documented.
- Controller mapping should be treated as unverified unless tested on the intended controller and platform.
