# 2Mars V5.1 — Design a Rover Mission

*Design your mission. Operate your rover. Discover Mars.*

**2Mars** is an educational Mars mission design and exploration game created by Team SpaceNuts for the **NASA Space Apps Challenge 2026 — Space Mission Design Game**.

**CURRENT SOURCE** **Project version 5.1.0** · Godot 4.7 · GDScript

## Overview

Players take part in a complete Mars rover mission, from the first briefing to the final debrief. They define objectives, make mission-planning choices, configure a rover, assess readiness, travel to Mars and carry out science operations. Rover design and operational constraints shape the available choices and mission outcome.

## Mission flow

1. **Briefing** — meet Dr. Owen, name the mission and review its objectives.
2. **Planning** — choose a mission profile, launch scenario, landing area and science priorities.
3. **Rover workshop** — configure a rover using 30 components in seven categories.
4. **Readiness review** — inspect design blockers, risks, limitations and recommendations.
5. **Launch and transit** — progress through launch, cruise and landing events.
6. **Mars operations** — drive, investigate targets, use instruments, collect samples, manage resources and transmit data.
7. **Debrief and progression** — review mission performance, scientific results and achievements.

## Game modes

- **Single player:** plan, build and operate a rover independently.
- **Local cooperative play:** two players share one computer and coordinate mission responsibilities.
- **Expedition co-op (V5.1):** two rovers operate in the same mission using a fixed split-screen layout. Each rover has its own position, speed, energy, health and sample tubes, while mission time, memory, data, objectives and rewards are shared.

There is no online multiplayer.

## Expedition co-op controls

| Action | Player 1 (left) | Player 2 (right) |
|---|---|---|
| Move | W A S D | Arrow keys |
| Study / cycle panel option | E | Period (.) |
| Confirm action / minigame | Space | Enter |
| Transmit | T | Comma (,) |
| Pause | Esc | Esc |

In a rock-study panel, E or . cycles through the available options; Space or Enter performs the selected action. Number keys 1–6 can also select options.

## Science Library

The in-game Science Library includes seven Perseverance science instruments, rover components, real sample examples, NASA-to-game explanations, mission stories, a glossary and source links. It distinguishes NASA-sourced information from game-balance values and fictional story elements.

## Run the project

1. Install **Godot Engine 4.7**.
2. Open `project.godot` from this folder in Godot.
3. Press **F5** to run the project.

No extra Godot plugins are required by the project configuration. Player progress is saved in the Godot user data directory.

## Automated test assets

V5 includes test scenes for game-flow checks, script compilation and layout inspection. Run from the repository root:

```bash
godot --headless --path Game-versions/V5 res://tests/Compile.tscn
godot --headless --fixed-fps 60 --path Game-versions/V5 res://tests/Bot.tscn
godot --headless --path Game-versions/V5 res://tests/Layout.tscn
```

The presence of test scripts does not by itself prove a successful run. See the [test report](../../evidence/TEST_REPORT.md) for the distinction between available coverage and recorded execution evidence.

## Project structure

| Path | Contents |
|---|---|
| `project.godot` | Godot configuration and project version. |
| `scenes/` | Main scene. |
| `scripts/` | Game state, data, interface, rover/world systems and mission screens. |
| `assets/`, `parts/`, `fonts/` | Interface icons, rover parts, fonts and related assets. |
| `shaders/` | Visual shaders. |
| `tests/` | Automated test scenes and scripts. |
| `video/` | Launch animation used by the game. |
| `docs/` | Technical, scientific, attribution and challenge-alignment documentation. |

## Scientific scope and limitations

2Mars is an educational game, not a professional mission-design or flight-dynamics tool. Mission planning, launch windows, landing, rover statistics, resource limits and communication rates include simplified game models. The game does not calculate real orbital trajectories or Delta-V and does not directly load live NASA datasets or APIs.

NASA has not confirmed life on Mars. The game does not claim otherwise. 2Mars is not affiliated with or endorsed by NASA.

## Documentation

- [V5 documentation index](docs/README.md)
- [Challenge alignment](../../evidence/CHALLENGE_ALIGNMENT.md)
- [Educational design](../../evidence/EDUCATIONAL_DESIGN.md)
- [Mission walkthrough](../../evidence/MISSION_CASE_STUDY.md)
- [Test report](../../evidence/TEST_REPORT.md)
- [AI and asset attribution](../../evidence/AI_AND_ASSET_ATTRIBUTION.md)

## Credits

Created by **Team SpaceNuts · Panama**. Built with Godot 4.7 and GDScript. Production tools and asset attribution are documented in the [resource audit](docs/RESOURCE_AUDIT.md).
