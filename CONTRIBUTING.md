# Contributing to 2Mars

Thank you for your interest in improving 2Mars. The current source project is **V5.1**, located in `Game-versions/V5/`.

## Before making changes

1. Read the [main README](README.md) and [V5 game guide](Game-versions/V5/README.md).
2. Use **Godot Engine 4.7** for the current project.
3. Keep changes focused and explain their purpose.
4. Preserve the English and Spanish experience when editing player-facing text.
5. Keep archived V1, V3 and V4 projects unchanged unless a change specifically concerns their historical documentation.

## Project standards

### Gameplay and code

- Follow the existing V5 architecture and GDScript conventions.
- Avoid adding external plugins or dependencies without explaining why they are needed.
- Consider save compatibility when changing persistent data.
- Do not describe a feature as tested unless it has actually been run.

### Science and factual accuracy

- Prefer original NASA and NASA/JPL sources.
- Add source references when introducing scientific facts.
- Distinguish verified facts from game-balance values and fictional story content.
- Update [science traceability](Game-versions/V5/docs/SCIENCE_TRACEABILITY.md) when a new source informs a gameplay mechanic or decision.
- Do not imply NASA endorsement, live API use or direct dataset integration unless implemented.

### Visuals, audio and attribution

- Preserve licenses and attribution notices.
- Document the origin and tool used for new visual, audio or video assets.
- Do not add third-party assets without permission or a compatible license.

## Testing

From the repository root, run the V5 checks with Godot 4.7:

```bash
godot --headless --path Game-versions/V5 res://tests/Compile.tscn
godot --headless --fixed-fps 60 --path Game-versions/V5 res://tests/Bot.tscn
godot --headless --path Game-versions/V5 res://tests/Layout.tscn
```

If a change affects localization, check both English and Spanish flows. Describe manual test steps for gameplay changes.

## Pull requests

Include a concise summary, affected systems, steps to reproduce or test, screenshots for visible changes and any new source or asset credits. Do not commit local Godot cache folders, temporary exports, personal save files or private credentials.

## Reporting issues

Include the Godot version, operating system, steps to reproduce, expected result, actual result and relevant screenshots or logs. Remove personal information from logs before posting.

---
*2Mars · Team SpaceNuts*
