# 2Mars — Design a Rover Mission (V3)

*Design your mission. Operate your rover. Discover Mars.*

2D educational mission-design game for the NASA Space Apps Challenge 2026 (Space Mission Design Game), by team SpaceNuts.
Developed in several sessions during November 14 and 15.

V3 is built on the V1 project (`to-mars-game.zip`); nothing was rebuilt from scratch. It covers what V2 added and the list V2 left pending.

## Run

Open `project.godot` with **Godot 4.7** and press **F5**. No extra dependencies, no plugins.

The first start asks for language (English / Español) and input mode (mouse, keyboard, or both). Both can be changed later in Settings.

Saves: `user://2mars_save.json` (three campaign files and a separate Sandbox state). The project keeps the old user folder name, so a ToMars 1.0 save (`tomars_save.json`) is imported into file 1 the first time and is never modified.

## The mission flow

1. **Dr. Owen's briefing** — your name, rover and mission names, and the six connected factors: time, data, budget, mass, energy, communications.
2. **Earth station** — current rover, real statistics, budget, and advice based on your saved missions.
3. **Mission panel** — a real-time Mars globe (drag to rotate, wheel to zoom) and the four zones of Jezero Crater.
4. **Mission planning** — launch window, mission profile, landing site, science priority. Each changes limits, time, data target or the landing.
5. **Workshop** — 30 components from the team's engineering workbook in 7 categories, with a before/after comparison for every part.
6. **Mission Readiness** — critical blockers, operational risks, scientific limitations, optional recommendations.
7. **Launch → cruise → landing** — two cruise events with decisions, and a landing whose outcome depends on the design.
8. **Operations on Mars** — drive, photograph (up to 3 angles), analyse, sample, store, transmit.
9. **Debrief** — six dimensions, root causes, what went well, and what to change next time.

Required objectives complete the mission. Optional objectives are extra science and achievements.

## Controls

| Action | Keyboard | Mouse |
|---|---|---|
| Drive | WASD / arrows | hold the button on the ground |
| Study a rock | E | click the rock |
| Choose / confirm | 1–6 · Enter | click the button |
| Instrument action | Space | click |
| Transmit | T | Transmit button |
| Data · AutoNav · Controls | Tab · G · H | action bar |
| Weather · Oxygen · Radar | M · O · R | action bar |
| Pause | Esc | Pause button |
| Fullscreen | F11 | |

**Local co-op (two players, one computer).** Mission Commander: arrows drive, T transmits, Enter confirms. Rover Engineer & Scientist: E, 1–6, Space, M, O, R, G; F confirms (button A on a controller is mapped but was not tested). Three decisions need both players: the mission plan, the design review before launch, and ending the mission.

**Sandbox.** Free workshop with adjustable mass and budget limits, any zone, a test drive, reset and its own hangar. It never changes campaign rovers, progress or history.

## Tests

Run with a fixed frame rate so that timing is deterministic. The bot uses its own save file.

```
godot --headless --fixed-fps 60 res://tests/Bot.tscn                # everything
godot --headless --fixed-fps 60 res://tests/Bot.tscn -- --es        # everything, in Spanish
godot --headless --fixed-fps 60 res://tests/Bot.tscn -- --quick     # one full mission, start to debrief
godot --fixed-fps 60 res://tests/Bot.tscn -- --shots=FOLDER         # also saves screenshots (needs a display)
godot --headless res://tests/Compile.tscn                           # compiles every script
```

The bot plays the real game: it presses the interface buttons, drives with input actions and runs the instruments under the normal rules.

## Structure

- `scripts/game.gd` — global state: settings, save files, plan, achievements, mission history, audio
- `scripts/data.gd` — component catalogue, groups, instruments, rocks, zones, planning options, quizzes, readiness rules, recommendations, real NASA facts and sources
- `scripts/ui.gd`, `scripts/art.gd`, `scripts/screen.gd`, `scripts/settings.gd` — UI kit, vector art, screen base (Dr. Owen panel, co-op gate), settings dialog
- `scripts/screens/` — boot, menu, profiles, achievements, briefing, hub, zones, plan, design, transit, ops, debrief, progress, library
- `shaders/globe.gdshader` — the Mars globe
- `assets/` — fonts, synthesised audio, the team's 2MARS logo
- `docs/` — requirement checklist, science traceability, rubric mapping, cinematic briefs, handoff notes

## Real data and game model

- **Verified NASA information** is shown apart, with its source: the library tabs "The real rover" and "Real samples", and Dr. Owen's mission stories.
- **Game model.** Component mass, power, credits and scores come from the team's workbook and are game parameters. Battery Wh, memory MB, link rates, times and the landing are balancing values. One second of play is ten mission minutes. Example of the difference: the game's RTG gives 300 W; Perseverance's real MMRTG gives about 110 W.
- **Fiction.** Dr. Owen, your team, your rover, the mission, and every rock and sample you study.

NASA has not confirmed life on Mars; the game never says otherwise. 2Mars is not affiliated with or endorsed by NASA.

## Credits

Team SpaceNuts (Panama). Art: original vector art drawn by code; 2MARS logo by the team. Sound and music: synthesised for the game. Fonts: Fredoka and Nunito (SIL Open Font License). Engine: Godot 4.7.
