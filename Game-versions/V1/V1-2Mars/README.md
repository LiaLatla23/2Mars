# ToMars — game

*Design your mission. Operate your rover. Discover Mars.*

2D educational mission-design game for the NASA Space Apps Challenge 2026 (Space Mission Design Game), by team SpaceNuts.

## Run
Open `project.godot` with **Godot 4.7** and press **F5**. No extra dependencies.

## Controls
WASD / arrows: drive · E or Space: study a rock (then 1-5 to pick an instrument) · T: transmit · M: weather station · O: oxygen run · R: radar · Esc: pause · F11: fullscreen

## Structure
- `scripts/game.gd` — global state, save, language (EN/ES)
- `scripts/data.gd` — parts, instruments, rocks, zones, quizzes, real NASA facts and sources
- `scripts/art.gd`, `scripts/ui.gd` — low-poly vector art drawn by code and the UI kit
- `scripts/screens/` — menu, mission map, mission design, operations, debrief, library
- `tests/Bot.tscn` — smoke bot: `godot --headless res://tests/Bot.tscn`

Game values (kg, credits, MB, seconds) are a simplified educational model, not NASA figures. Real Perseverance facts are listed separately in the in-game library with their sources. Not affiliated with or endorsed by NASA.
