# Contributing to 2Mars

Thank you for helping improve 2Mars. The current development target is **V4**, located in `Game-versions/V4/`.

## Before making changes

1. Read the [main README](README.md) and [V4 game guide](Game-versions/V4/README.md).
2. Use **Godot Engine 4.7** for the V4 project.
3. Keep changes focused and explain the reason for them.
4. Do not modify V1 or V3 when the change is intended for the current game.
5. Preserve the English and Spanish experience when editing player-facing text.

## Project standards

### Gameplay and code
- Keep gameplay rules and data consistent with the existing V4 architecture.
- Avoid adding external plugins or dependencies without explaining why they are needed.
- Keep save compatibility in mind; document changes to save data.
- Do not claim a feature is tested unless it has actually been run.

### Science and factual accuracy
- Prefer original NASA and NASA/JPL sources.
- Add or update source references when introducing scientific facts.
- Distinguish verified facts from game-balance values and fictional story content.
- Update `SCIENCE_TRACEABILITY.md` when a new source informs a gameplay mechanic or decision.
- Never imply NASA endorsement or direct dataset/API integration unless that is genuinely implemented.

### Visuals, audio and attribution
- Preserve existing licenses and attribution notices.
- Document the origin and tool used for newly added visual, audio or video assets.
- Do not add third-party assets without permission or a compatible license.
- Keep source assets separate from exported builds when practical.

## Testing

From the repository root, run the V4 checks:

```bash
godot --headless --path Game-versions/V4 res://tests/Compile.tscn
godot --headless --fixed-fps 60 --path Game-versions/V4 res://tests/Bot.tscn
```

If a change affects localization, also run the bot with `-- --es`. If it affects a specific gameplay system, describe the manual test steps in your pull request.

## Pull requests

Please include:
- A short summary of the change and its purpose.
- The files or systems affected.
- Steps to reproduce or test the change.
- Screenshots or a short clip for visible UI/gameplay changes.
- Any new sources, licenses or asset credits.

Keep pull requests small enough to review. Do not commit local Godot cache folders, temporary exports, personal save files, or private credentials.

## Reporting issues

When opening an issue, include the Godot version, operating system, steps to reproduce, expected result, actual result and relevant screenshots or logs. Remove personal information from logs before posting.

---

*Thank you for helping make every mission decision count.*
