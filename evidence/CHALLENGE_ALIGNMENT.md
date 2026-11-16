# Challenge alignment · 2Mars V5.1

This document maps the current V5.1 implementation to the central activities of the NASA Space Apps **Space Mission Design Game** challenge. It is supporting repository evidence, not a copy of the official Project Submission or a claim of an official judging score.

## Mission-design activities

| Activity | What players do in 2Mars | Where to inspect |
|---|---|---|
| Define mission goals | Review the briefing and choose scientific priorities. | `Game-versions/V5/scripts/screens/briefing.gd`, `data.gd` |
| Plan the mission | Select a mission profile, launch scenario, landing area and science priority. | `Game-versions/V5/scripts/screens/plan.gd`, `data.gd` |
| Design the rover | Configure from 30 components across seven categories; balance mass, cost, power, mobility, storage and instrument compatibility. | `Game-versions/V5/scripts/screens/design.gd`, `data.gd` |
| Assess readiness | Review blockers, limitations, risks and recommendations before launch. | `Game-versions/V5/scripts/data.gd`, `scripts/screens/design.gd` |
| Launch and travel | Progress through launch, cruise and landing events. | `Game-versions/V5/scripts/screens/transit.gd`, `Game-versions/V5/video/launch.ogv` |
| Operate on Mars | Drive, photograph and analyse targets, use instruments, collect samples, manage resources and transmit data. | `Game-versions/V5/scripts/screens/ops.gd` |
| Evaluate the mission | Review mission results, progress, achievements and scientific inventory. | `Game-versions/V5/scripts/screens/debrief.gd`, `progress.gd`, `achievements.gd` |

## Distinctive design choices

- Rover configuration influences capabilities and constraints during surface operations.
- Planning, engineering, launch/transit, science operations and debrief are connected in one experience.
- The Science Library links NASA/JPL information to selected mechanics and player decisions.
- English and Spanish interfaces and local cooperative play are included.
- V5.1 Expedition mode allows two rovers to share one mission through a fixed split-screen view.

## Scientific and simulation boundaries

2Mars is an educational game, not professional mission-design software. It does not calculate real orbital trajectories or Delta-V, use live NASA APIs or directly load NASA planetary datasets. Launch windows, mass and budget limits, landing outcomes, rover statistics and several time/resource values are simplified game models. Real facts, game-balance values and fictional elements are distinguished in the [science traceability](../Game-versions/V5/docs/SCIENCE_TRACEABILITY.md).

## How to verify

- Open the [web demo](https://2mars.vercel.app/).
- Follow the [V5.1 game guide](../Game-versions/V5/README.md).
- Inspect the [V5 source project](../Game-versions/V5/).
- Review the [test report](TEST_REPORT.md) for test coverage and execution limits.

This mapping describes the implementation documented in the repository. It is not independent certification of scientific accuracy, educational effectiveness or external usability.
