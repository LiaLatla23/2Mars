# NASA Resources Used in 2Mars

**Project:** 2Mars — NASA Space Apps Challenge 2026  
**Team:** SpaceNuts  
**Reviewed:** November 15, 2026

This document separates NASA/JPL resources connected to the current V4 game from additional references consulted for mission-planning research. It records what each source contributes and avoids implying that the game imports NASA datasets or performs calculations it does not implement.

## 1. NASA/JPL links listed in the in-game Science Library

The in-game Science Library lists 11 NASA/JPL links under **Sources & Credits** (V4 scripts/data.gd, Data.SOURCES). This is the complete in-game credit list, not a claim that every link has its own gameplay mechanic. Of these, six sources are explicitly mapped to a mechanic, player decision, and consequence in the interactive **NASA → Game** tab (V4 Data.TRACE). Five additional NASA/JPL links support specific Dr. Owen mission stories. The remaining landing-telecommunications press-kit link appears in Sources & Credits but is not a separate row in the interactive traceability table. The classifications below make these differences explicit.

| # | NASA/JPL resource (as listed in the game) | Information used | Exact in-game connection |
|---|---|---|---|
| 1 | [Mars 2020 Perseverance · Science Objectives](https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/) | Four science objectives: geology, astrobiology, sample caching, and preparation for human exploration. | Listed in Sources & Credits; explicit NASA → Game trace row 1 connects the objectives to the four campaign zones, instrument choices, and blocked objectives when required equipment is absent. |
| 2 | [Mars 2020 Perseverance · Science Instruments](https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/) | Capabilities of Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, RIMFAX, and MOXIE; WATSON is SHERLOC's camera, not an eighth science instrument. | Linked from each instrument detail card; explicit NASA → Game trace row 2 connects instrument capabilities to payload selection, mass/budget/deck limits, and different science outputs. PIXL and SHERLOC require the arm in the game model. |
| 3 | [Mars 2020 Perseverance · Rover Components](https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/) | Rover architecture, MMRTG and batteries, rocker-bogie mobility, robotic arm, and antennas. | Listed in Sources & Credits; explicit NASA → Game trace row 3 connects power, storage, suspension, and antenna trade-offs to rover configuration and operational consequences. The game distinguishes its 300 W RTG parameter from Perseverance's real MMRTG output of about 110 W at mission start. |
| 4 | [Mars 2020 Perseverance · Mars Rock Samples](https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/) | Real Perseverance sample names, rock types, collection sites, and context. | Linked from the Real Samples cards; explicit NASA → Game trace row 5 connects real sample context to the in-game sample catalogue, context photos, limited tubes, and sample-selection decisions. The samples collected in 2Mars are fictional. |
| 5 | [NASA · Assessing Perseverance's First Sample Attempt](https://science.nasa.gov/blog/assessing-perseverances-first-sample-attempt/) | Perseverance's first Roubion coring attempt returned an empty tube after the rock crumbled. | Linked from Dr. Owen's Roubion story; explicit NASA → Game trace row 6 connects the event to the failed-sample mechanic and the choice to inspect images, try a harder rock, or use the collector. |
| 6 | [NASA Glenn · Mars Perseverance Communications (NTRS 20210010148)](https://ntrs.nasa.gov/api/citations/20210010148/downloads/Mars%20Perseverance%20Communications%202021%20revised.pdf) | UHF relay up to 2 Mbps through orbiters; direct-to-Earth X-band around 160–500 bps; limited orbiter visibility. | Listed in Sources & Credits; explicit NASA → Game trace row 4 connects communication windows, limited memory, antenna selection, and data-return decisions. Gameplay transmission rates and timing are accelerated. |
| 7 | [NASA/JPL · Mars 2020 Landing Press Kit · Telecommunications](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/spacecraft/telecommunications) | Mars 2020 spacecraft telecommunications during cruise and landing. | Appears in Sources & Credits. It is not a separate row in Data.TRACE and the game does not reproduce the complete flight telecommunications architecture. The V4 Markdown traceability notes discuss the landing communication sequence as a simplified teaching scenario. |
| 8 | [NASA/JPL · Perseverance Mars Rover Gets Its Wheels and Air Brakes](https://www.jpl.nasa.gov/news/nasas-perseverance-mars-rover-gets-its-wheels-and-air-brakes/) | Perseverance's redesigned wheels: 48 curved treads and about 52.6 cm in diameter. | Listed in Sources & Credits and linked from Dr. Owen's Curiosity/Perseverance wheels story. The V4 component catalogue also models wheel choices and wear. The 25% reduction in game wear is a balancing value, not a NASA result. |
| 9 | [NASA/JPL · Oxygen-Generating Experiment MOXIE Completes Mars Mission](https://www.jpl.nasa.gov/news/nasas-oxygen-generating-experiment-moxie-completes-mars-mission/) | MOXIE completed 16 oxygen-production runs and produced 122 grams of oxygen in total. | Listed in Sources & Credits and linked from Dr. Owen's MOXIE story. The instrument detail card explains that MOXIE was a technology demonstration, not a life-support system. |
| 10 | [NASA — Opportunity Rover Mission Comes to an End](https://www.nasa.gov/press-release/nasas-record-setting-opportunity-rover-mission-on-mars-comes-to-end) | Opportunity was designed for a 90-Martian-day mission and operated for almost 15 years. | Informs Dr. Owen's Opportunity/dust story and the discussion of rover longevity and environmental hazards. It is historical context, not a simulation of the Opportunity mission. |
| 11 | [NASA · Mars 2020 mission blog (landing day, one-way light time)](https://blogs.nasa.gov/mars2020/author/nhartono) | One-way light time was 11 minutes 22 seconds on Perseverance's landing day, February 18, 2021. | Listed in Sources & Credits and linked from Dr. Owen's story explaining why the rover lands autonomously. This is an author archive URL, not a deep link to the individual landing-day post; the delay varies with planetary distance. |

## 2. Exact coverage in the interactive Science Library

The current V4 code has six rows in Data.TRACE, shown in the **NASA → Game** tab. They reference source indices 1, 2, 3, 6, 4, and 5 in the Sources & Credits list (the table above is numbered from 1):

1. Science Objectives → campaign zones, required objectives, and instrument choices.
2. Science Instruments → instrument capabilities, payload limits, and different science outputs.
3. Rover Components → power, storage, suspension, antenna trade-offs, and operational consequences.
4. NASA Glenn Communications → orbiter passes, memory, transmission decisions, and data return.
5. Mars Rock Samples → real sample context, sample catalogue, and sample-selection decisions.
6. First Sample Attempt → failed-sample event and alternative sampling decisions.

Five additional NASA/JPL links support Dr. Owen stories and are linked from those story cards: wheel design, Opportunity and dust, Roubion's failed sample, MOXIE, and landing-day communication delay. The Spirit and sand-trap story names NASA/JPL as its source but has no source URL in the current story data. The Mars 2020 landing telecommunications press-kit link is listed in Sources & Credits but is not a separate Data.TRACE row.

The instrument cards link to the Science Instruments source; the Real Samples cards link to the Mars Rock Samples page. The Real Rover panel displays sourced facts, but the panel itself should not be interpreted as a separate source-to-mechanic trace row.

## 3. Additional NASA mission-planning references

The following sources are documented in [SPACE_MISSION_PLANNING_SOURCES_EN.md](SPACE_MISSION_PLANNING_SOURCES_EN.md). They support research into mission-planning concepts. They must not be described as imported data or implemented high-fidelity calculations unless a corresponding feature and data source are added to the game.

| NASA/JPL reference | Concept researched | Boundary when describing the game |
|---|---|---|
| [Mars 2020 Perseverance Landing Press Kit — Mission Overview](https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/) | Mars 2020 mission architecture, Atlas V 541 launch vehicle, spacecraft and landing context. | Does not provide a universal payload-capacity table for every launch vehicle or mission configuration. |
| [NASA Basics of Space Flight — Chapter 4: Trajectories](https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/) | Earth–Mars geometry, transfer opportunities, trajectory timing, and flight-time/energy trade-offs. | The game is not a numerical astrodynamics simulator and does not calculate real orbital trajectories or Delta-V. |
| [NASA Basics of Space Flight — Chapter 14: Launch](https://science.nasa.gov/learn/basics-of-space-flight/chapter14-1/) | Launch vehicle and payload concepts; distinction between rover mass and the broader mission stack. | Game mass limits and vehicle options are educational abstractions unless tied to a specific sourced performance value. |
| [NASA Ames — Flight Dynamics](https://www.nasa.gov/ames-engineering/spaceflight-division/flight-dynamics/) | Trajectory Browser context, including launch dates, flight times, and Delta-V constraints. | 2Mars does not import live Trajectory Browser results. |
| [Mars 2020 Perseverance Launch Press Kit](https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/) | Launch period and launch-window concepts from a real Mars mission. | Game launch windows are simplified educational representations, not calculated future launch dates. |
| [Mars 2020 Landing Site Down-Select (NASA/JPL PDF)](https://marsnext.jpl.nasa.gov/documents/Mars%202020%20landing%20site%20down-select%20Feb%202017.pdf) | How scientific value, terrain safety, traverse, and operational constraints informed landing-site evaluation. | The game does not reproduce the official selection model or claim its own site scores are NASA scores. |

## 4. Research resources not integrated as game data or assets

The broader research inventory also mentions NASA Mars Trek, Mars raw-image galleries, Science Updates, Mission Design Lab, NASA Mission Visualization, and CubeSat 101.

These are research or reference materials, not evidence that their datasets, imagery, maps, or software are embedded in the reviewed V4 game. The V4 resource audit records that:

- No NASA planetary dataset (for example, PDS, MRO, Curiosity, or InSight data) is directly loaded by the game.
- No NASA rover photographs, satellite maps, or terrain datasets were identified as game visuals.
- The rover, terrain, Mars globe, workshop, and landscape visuals in V4 are generated from project code/geometry; the globe is an artistic representation, not a NASA map.
- The game uses NASA/JPL mission documentation as research references. It does not use a live NASA API or data feed.

## 5. Scientific accuracy and gameplay simplifications

2Mars is an educational game, not professional mission-design software. The following distinctions are important:

- **Power:** the game RTG value is 300 W; the real Perseverance MMRTG is approximately 110 W at the beginning of the mission. These are not interchangeable specifications.
- **Communications:** gameplay data rates and time are accelerated. Real communication figures are shown separately for context.
- **Mission time:** the game uses a compressed time scale (one second of game time represents ten minutes of mission time, as documented in the V4 audit).
- **Samples:** game rocks and samples are fictional; real Perseverance samples are shown as references or analogues.
- **MOXIE:** it was an oxygen-production technology demonstration, not a complete life-support system.
- **Astrobiology:** organic compounds or potentially habitable environments are not proof of life. NASA has not confirmed life on Mars.
- **Engineering upgrades and statistics:** component ratings, budgets, mobility, wear, and performance modifiers are game parameters unless explicitly identified as real-world facts with a source.
- **Mission planning:** launch windows, vehicle limits, destination scores, and trajectory profiles are simplified educational abstractions. The game does not calculate real orbital mechanics or Delta-V.

## 6. In-game and repository traceability

The in-game Science Library includes **Sources & Credits** and **NASA → Game** sections. The repository provides additional detail in:

- [V4 scientific traceability matrix](../Game-versions/V4/docs/SCIENCE_TRACEABILITY.md) — source → information → mechanic → player decision → consequence.
- [V4 resource audit](../Game-versions/V4/docs/RESOURCE_AUDIT.md) — evidence, attributions, verified facts, unresolved items, and AI/media audit.
- [Mission-planning research](SPACE_MISSION_PLANNING_SOURCES_EN.md) — NASA sources and limitations for planning concepts.

**Evidence scope:** this inventory reflects the reviewed V4 source code and documentation. If later versions change game mechanics or sources, this file and the traceability matrix should be reviewed together.

---

*2Mars | Team SpaceNuts | NASA Space Apps Challenge 2026*
