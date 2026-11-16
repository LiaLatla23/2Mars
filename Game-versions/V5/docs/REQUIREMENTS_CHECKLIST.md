# V5.1 implementation overview

This document summarizes the current source project in `Game-versions/V5/`. It is a reviewer-oriented feature map, not an internal task tracker.

## Mission experience

| Capability | V5.1 implementation | Source location |
|---|---|---|
| Mission briefing | Dr. Owen introduces the mission and its goals. | `scripts/screens/briefing.gd` |
| Mission planning | Mission profile, launch scenario, landing area and science priorities. | `scripts/screens/plan.gd`, `scripts/data.gd` |
| Rover engineering | Component catalogue and configuration across seven categories; game evaluates design characteristics. | `scripts/screens/design.gd`, `scripts/data.gd` |
| Readiness review | Design blockers, risks, limitations and recommendations. | `scripts/data.gd`, `scripts/screens/design.gd` |
| Launch and transit | Launch, cruise and landing sequence with mission events. | `scripts/screens/transit.gd`, `video/launch.ogv` |
| Mars surface operations | Rover movement, target investigation, science instruments, sampling, resource and data management. | `scripts/screens/ops.gd`, `scripts/world3d.gd`, `scripts/rover3d.gd` |
| Mission debrief | Mission results and progress review. | `scripts/screens/debrief.gd`, `scripts/screens/progress.gd` |
| Science Library | Instruments, rover parts, real samples, NASA-to-game explanations, mission stories, glossary and sources. | `scripts/screens/library.gd`, `scripts/data.gd` |
| Local multiplayer | Shared local play and V5.1 Expedition mode with two rovers in split-screen. | `scripts/screens/ops.gd` and related mission/UI scripts |
| Language support | English and Spanish player-facing experience. | `scripts/data.gd`, screen and UI scripts |

## Engineering catalogue and educational model

The V5 data catalogue contains 30 rover components in seven categories. Component mass, power, credits, science, mobility and reliability values are project game parameters based on the team's engineering workbook. They are not certified NASA specifications.

The game separately identifies real-world Perseverance information and simplified game-model values. For example, the project's RTG output is a balancing value and should not be represented as the real Perseverance MMRTG output.

## Verification assets

The repository includes:

- `tests/Compile.tscn` and `tests/compile.gd` for script compilation checks.
- `tests/Bot.tscn` and `tests/bot.gd` for automated game-flow checks.
- `tests/Layout.tscn` and `tests/layout.gd` for layout checks.

See the [test report](../../../evidence/TEST_REPORT.md) for commands and the distinction between test assets and recorded test execution.

## Scope boundaries

2Mars is an educational game. It is not a professional spacecraft design tool or high-fidelity orbital simulator. It does not calculate real orbital trajectories or Delta-V, connect to live NASA APIs or directly load NASA planetary datasets. Several mission, resource and landing parameters are simplified game models.
