# NASA Resources Used in 2Mars

**Project:** 2Mars — NASA Space Apps Challenge 2026  
**Team:** SpaceNuts  
**Reviewed:** November 15, 2026

This document separates NASA/JPL resources connected to the current V4 game from additional references consulted for mission-planning research. It records what each source contributes and avoids implying that the game imports NASA datasets or performs calculations it does not implement.

## 1. NASA/JPL resources integrated into the game

The following resources are listed in the in-game Science Library under **Sources & Credits** (V4 scripts/data.gd, Data.SOURCES). Their information informs game facts, explanations, mission stories, or mechanics.

| # | NASA/JPL resource | Information used | Where/how it contributes to 2Mars |
|---|---|---|---|
| 1 | [Mars 2020 Perseverance — Science Objectives](https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/) | Perseverance's four objectives: geology, astrobiology, sample caching, and preparation for future human exploration. | Informs campaign science themes and exploration-zone objectives. Players need suitable instruments to complete certain investigations. |
| 2 | [Mars 2020 Perseverance — Science Instruments](https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/) | Capabilities of Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, RIMFAX, and MOXIE; distinction between SHERLOC and its WATSON camera. | Informs the seven instrument choices, the kinds of scientific evidence they produce, and equipment compatibility. PIXL and SHERLOC are treated as arm-dependent in the game model. |
| 3 | [Mars 2020 Perseverance — Rover Components](https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/) | Rover architecture, MMRTG and batteries, rocker-bogie mobility, robotic arm, antennas, and sample system. | Informs the rover component catalogue and engineering trade-offs involving power, mobility, communications, mass, and sample handling. The game explicitly distinguishes its 300 W RTG parameter from the real MMRTG's approximately 110 W at the start of the mission. |
| 4 | [Mars 2020 Perseverance — Mars Rock Samples](https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/) | Real Perseverance sample names, geological context, and collection information. | Provides real-world analogues and context in the Science Library. Rocks and samples collected in the game are fictional and identified as such. |
| 5 | [Assessing Perseverance's First Sample Attempt](https://science.nasa.gov/blog/assessing-perseverances-first-sample-attempt/) | The first Roubion coring attempt produced an empty tube after the rock crumbled. | Informs the failed-sample event and Dr. Owen's Roubion story. Players review observations and decide whether to retry or select another target, spending additional time and energy. |
| 6 | [Mars Perseverance Communications — NASA Glenn (NTRS 20210010148)](https://ntrs.nasa.gov/api/citations/20210010148/downloads/Mars%20Perseverance%20Communications%202021%20revised.pdf) | Communication architecture, UHF relay rates up to approximately 2 Mbps through orbiters, limited orbiter visibility, and direct-to-Earth X-band rates around 160–500 bps. | Informs orbiter communication opportunities, onboard data storage, antenna choices, transmission decisions, and data-return/debrief mechanics. In-game rates and time are accelerated for playability; real figures are identified separately. |
| 7 | [Mars 2020 Landing Press Kit — Telecommunications](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/spacecraft/telecommunications) | Spacecraft communication systems and telecommunications during cruise and landing. | Provides background for communication-related transit events. The game does not reproduce the complete flight telecommunications architecture. |
| 8 | [NASA/JPL — Perseverance Gets Its Wheels and Air Brakes](https://www.jpl.nasa.gov/news/nasas-perseverance-mars-rover-gets-its-wheels-and-air-brakes/) | Perseverance's redesigned wheels, including 48 curved treads and an approximately 52.6 cm diameter. | Informs a real-rover fact, Dr. Owen's wheel story, rocky-terrain wear, and the wheel-tread upgrade. The upgrade's 25% reduction in game wear is a balancing value, not a NASA-reported performance result. |
| 9 | [NASA/JPL — MOXIE Completes Its Mars Mission](https://www.jpl.nasa.gov/news/nasas-oxygen-generating-experiment-moxie-completes-mars-mission/) | MOXIE's technology-demonstration results: 16 oxygen-production runs and 122 grams of oxygen in total. | Informs the MOXIE instrument entry, a mission objective, and Dr. Owen's oxygen-generation story. MOXIE is a technology demonstration, not a complete life-support system. |
| 10 | [NASA — Opportunity Rover Mission Comes to an End](https://www.nasa.gov/press-release/nasas-record-setting-opportunity-rover-mission-on-mars-comes-to-end) | Opportunity was designed for a 90-Martian-day mission and operated for almost 15 years. | Informs Dr. Owen's Opportunity/dust story and the discussion of rover longevity and environmental hazards. It is historical context, not a simulation of the Opportunity mission. |
| 11 | [NASA Mars 2020 Mission Blog — Landing Day](https://blogs.nasa.gov/mars2020/author/nhartono) | One-way light time of 11 minutes 22 seconds on Perseverance's landing day, February 18, 2021. | Informs Dr. Owen's communication-delay explanation and why a rover cannot be joystick-controlled in real time from Earth. The delay varies with planetary distance; the game simplifies the landing sequence. |

## 2. Additional NASA mission-planning references

The following sources are documented in [SPACE_MISSION_PLANNING_SOURCES_EN.md](SPACE_MISSION_PLANNING_SOURCES_EN.md). They support research into mission-planning concepts. They must not be described as imported data or implemented high-fidelity calculations unless a corresponding feature and data source are added to the game.

| NASA/JPL reference | Concept researched | Boundary when describing the game |
|---|---|---|
| [Mars 2020 Perseverance Landing Press Kit — Mission Overview](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/) | Mars 2020 mission architecture, Atlas V 541 launch vehicle, spacecraft and landing context. | Does not provide a universal payload-capacity table for every launch vehicle or mission configuration. |
| [NASA Basics of Space Flight — Chapter 4: Trajectories](https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/) | Earth–Mars geometry, transfer opportunities, trajectory timing, and flight-time/energy trade-offs. | The game is not a numerical astrodynamics simulator and does not calculate real orbital trajectories or Delta-V. |
| [NASA Basics of Space Flight — Chapter 14: Launch](https://science.nasa.gov/learn/basics-of-space-flight/chapter14-1/) | Launch vehicle and payload concepts; distinction between rover mass and the broader mission stack. | Game mass limits and vehicle options are educational abstractions unless tied to a specific sourced performance value. |
| [NASA Ames — Flight Dynamics](https://www.nasa.gov/ames-engineering/spaceflight-division/flight-dynamics/) | Trajectory Browser context, including launch dates, flight times, and Delta-V constraints. | 2Mars does not import live Trajectory Browser results. |
| [Mars 2020 Perseverance Launch Press Kit](https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/) | Launch period and launch-window concepts from a real Mars mission. | Game launch windows are simplified educational representations, not calculated future launch dates. |
| [Mars 2020 Landing Site Down-Select (NASA/JPL PDF)](https://marsnext.jpl.nasa.gov/documents/Mars%202020%20landing%20site%20down-select%20Feb%202017.pdf) | How scientific value, terrain safety, traverse, and operational constraints informed landing-site evaluation. | The game does not reproduce the official selection model or claim its own site scores are NASA scores. |

## 3. Research resources not integrated as game data or assets

The broader research inventory also mentions NASA Mars Trek, Mars raw-image galleries, Science Updates, Mission Design Lab, NASA Mission Visualization, and CubeSat 101.

These are research or reference materials, not evidence that their datasets, imagery, maps, or software are embedded in the reviewed V4 game. The V4 resource audit records that:

- No NASA planetary dataset (for example, PDS, MRO, Curiosity, or InSight data) is directly loaded by the game.
- No NASA rover photographs, satellite maps, or terrain datasets were identified as game visuals.
- The rover, terrain, Mars globe, workshop, and landscape visuals in V4 are generated from project code/geometry; the globe is an artistic representation, not a NASA map.
- The game uses NASA/JPL mission documentation as research references. It does not use a live NASA API or data feed.

## 4. Scientific accuracy and gameplay simplifications

2Mars is an educational game, not professional mission-design software. The following distinctions are important:

- **Power:** the game RTG value is 300 W; the real Perseverance MMRTG is approximately 110 W at the beginning of the mission. These are not interchangeable specifications.
- **Communications:** gameplay data rates and time are accelerated. Real communication figures are shown separately for context.
- **Mission time:** the game uses a compressed time scale (one second of game time represents ten minutes of mission time, as documented in the V4 audit).
- **Samples:** game rocks and samples are fictional; real Perseverance samples are shown as references or analogues.
- **MOXIE:** it was an oxygen-production technology demonstration, not a complete life-support system.
- **Astrobiology:** organic compounds or potentially habitable environments are not proof of life. NASA has not confirmed life on Mars.
- **Engineering upgrades and statistics:** component ratings, budgets, mobility, wear, and performance modifiers are game parameters unless explicitly identified as real-world facts with a source.
- **Mission planning:** launch windows, vehicle limits, destination scores, and trajectory profiles are simplified educational abstractions. The game does not calculate real orbital mechanics or Delta-V.

## 5. In-game and repository traceability

The in-game Science Library includes **Sources & Credits** and **NASA → Game** sections. The repository provides additional detail in:

- [V4 scientific traceability matrix](../Game-versions/V4/docs/SCIENCE_TRACEABILITY.md) — source → information → mechanic → player decision → consequence.
- [V4 resource audit](../Game-versions/V4/docs/RESOURCE_AUDIT.md) — evidence, attributions, verified facts, unresolved items, and AI/media audit.
- [Mission-planning research](SPACE_MISSION_PLANNING_SOURCES_EN.md) — NASA sources and limitations for planning concepts.

**Evidence scope:** this inventory reflects the reviewed V4 source code and documentation. If later versions change game mechanics or sources, this file and the traceability matrix should be reviewed together.

---

*2Mars | Team SpaceNuts | NASA Space Apps Challenge 2026*
