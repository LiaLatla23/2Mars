# Mission-planning sources · 2Mars V5.1

This document records the NASA/JPL references used to explain selected mission-planning ideas in the V5 Science Library. The game presents these ideas as educational context and simplified decisions, not as a flight-dynamics calculation.

## NASA/JPL references

| Subject | Reference | How it informs the game |
|---|---|---|
| Mars 2020 launch vehicle and launch facts | [NASA/JPL Mars 2020 Launch Press Kit — Quick Facts](https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/quick_facts/) | Provides historical context for the real Mars 2020 launch and spacecraft. |
| Mission architecture and launch period | [NASA/JPL Mars 2020 Launch Press Kit — Mission Overview](https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/) | Explains the cruise stage, aeroshell, descent stage and the relationship between launch timing and Earth–Mars geometry. |
| Mars 2020 arrival | [NASA/JPL Mars 2020 Landing Press Kit](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/) | Provides historical context for the real mission's interplanetary cruise and arrival. |
| Jezero landing hazards | [NASA Photojournal — Jezero's Hazard Map (PIA24167)](https://science.nasa.gov/photojournal/jezeros-hazard-map/) | Shows why landing-site selection and terrain hazards matter. |

## Educational concepts represented

The game introduces mission-planning concepts through simplified choices involving:

- Launch scenarios and launch timing.
- Spacecraft/rover mass and available launch capability.
- Cruise duration and mission time.
- Landing-area selection and terrain hazards.
- The relationship between mission objectives, payload and rover configuration.

These are educational abstractions. The game does not solve a Hohmann transfer, compute Delta-V, model a real launch vehicle's performance envelope or calculate an operational Mars entry/descent/landing trajectory.

## Game-model values

Launch vehicle names, capacities, credits, transfer durations, scenario windows, stage masses and landing multipliers are game parameters. They are not historical launch manifests or certified NASA engineering data. Refer to `Game-versions/V5/scripts/data.gd` for the implementation and to the in-game Science Library for the distinction between real-world context and the 2Mars model.

## Use in evaluation

Use these references to explain why mission design involves coupled decisions. Do not describe the game as a real orbital mechanics simulator or claim that its selected launch scenario represents a feasible launch date for an actual spacecraft.
