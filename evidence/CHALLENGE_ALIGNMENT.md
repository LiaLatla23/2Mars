# Challenge alignment · 2Mars V4

This document maps the implemented game to the central activities of a Space Mission Design Game. It is a repository evidence index, not a copy of the official NASA Space Apps Project Submission or a claim of an official judging score.

## Mission-design experience

| Mission-design activity | What the player does in 2Mars | Where to inspect it |
|---|---|---|
| Define mission goals | Reviews mission briefing, selects a mission profile and science priority. | `Game-versions/V4/scripts/screens/briefing.gd`, `plan.gd`, `Game-versions/V4/scripts/data.gd` |
| Plan a mission | Chooses launch window, landing site, profile and science priority within a simplified planning model. | `Game-versions/V4/scripts/screens/plan.gd`, `data.gd` |
| Design the spacecraft/rover | Configures a rover from a catalogue of 30 components and evaluates mass, cost, power, mobility, storage and instrument compatibility. | `Game-versions/V4/scripts/screens/design.gd`, `data.gd`, `Game-versions/V4/tests/bot.gd` |
| Assess readiness and risk | Reviews blockers, limitations, risks and recommendations before launch. | `Game-versions/V4/scripts/screens/design.gd`, `data.gd` |
| Launch and travel | Plays launch and transit sequences with simplified mission decisions. | `Game-versions/V4/scripts/screens/transit.gd`, `Game-versions/V4/assets/video/launch.ogv` |
| Operate on Mars | Drives the rover, investigates targets, operates instruments, collects samples, manages stored data and transmits results. | `Game-versions/V4/scripts/screens/ops.gd`, `hub.gd`, `data.gd` |
| Evaluate the mission | Reviews mission progress, inventory, achievements and debrief information. | `Game-versions/V4/scripts/screens/debrief.gd`, `progress.gd`, `achievements.gd` |

## Distinctive implementation choices

- The rover assembled in the workshop is represented in the 3D rover presentation and is used during surface operations.
- The game connects planning, engineering, launch/transit, surface science and debrief in one mission flow.
- Campaign and Sandbox provide different ways to engage with mission constraints.
- Local two-player mode assigns complementary Mission Commander and Rover Engineer & Scientist responsibilities.
- English and Spanish interfaces are included.
- The Science Library includes Sources & Credits and NASA → Game sections. The latter contains six explicit source-to-gameplay trace entries documented in [science traceability](../Game-versions/V4/docs/SCIENCE_TRACEABILITY.md).

## Scientific and simulation boundaries

2Mars is an educational game, not professional mission-design software. It does not calculate real orbital trajectories or Delta-V, does not load live NASA APIs or planetary datasets, and does not reproduce the complete Perseverance flight architecture. Launch windows, mass limits, landing and several resource/time values are simplified game models. Real facts, game-balance values and fictional story elements are distinguished in the Science Library and [NASA resource inventory](../research/NASA_RESOURCES_USED.md).

## How to verify

- Play the [web build](https://2mars.vercel.app/).
- Follow the [V4 installation and gameplay guide](../Game-versions/V4/README.md).
- Inspect the referenced scripts in the V4 project.
- Use the [test report](TEST_REPORT.md) for the current automated test commands and evidence limitations.

This mapping describes implemented features based on the repository structure and source reviewed for this documentation. It is not an independent certification of scientific or educational effectiveness.
