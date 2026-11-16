# V5.1 release notes

**Project:** 2Mars  
**Project version:** 5.1.0  
**Engine:** Godot 4.7  
**Team:** SpaceNuts

## Expedition cooperative mode

V5.1 includes a local Expedition mode with two rovers operating in one shared mission through a fixed split-screen layout.

- Player 1 controls the left rover with W, A, S and D.
- Player 2 controls the right rover with the arrow keys.
- Each rover has its own position, speed, energy, health and sample tubes.
- Mission time, memory, collected data, objectives and rewards are shared.
- If one rover is disabled, the other can continue; if both are disabled, the mission reports failure.

### Controls

| Action | Player 1 | Player 2 |
|---|---|---|
| Move | W A S D | Arrow keys |
| Study / cycle panel option | E | Period (.) |
| Confirm action / minigame | Space | Enter |
| Transmit | T | Comma (,) |
| Pause | Esc | Esc |

In the rock-study panel, E or . cycles through available options; Space or Enter performs the selected action. Number keys 1–6 can also select options.

## Mission-state design

Rover-specific movement and condition are tracked separately. Mission-level time, memory, data, objectives and rewards are shared. This allows both players to contribute to a common science and exploration outcome.

## Project status

V5.1 is the current source version in this repository. The [V5 game guide](../README.md) is the player-facing guide; the [V5 documentation index](README.md) links the technical and scientific references.
