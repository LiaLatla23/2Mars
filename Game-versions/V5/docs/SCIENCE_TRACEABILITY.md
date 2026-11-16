# Scientific traceability · 2Mars V5.1

## Purpose

2Mars uses NASA and NASA/JPL mission documentation to inform selected science concepts, rover systems, instruments, samples and communications. The in-game Science Library provides source links and distinguishes real mission information from game-model values and fictional content.

This document describes the traceability approach and its boundaries. It does not claim that the game is a scientific simulator or that every displayed value is a NASA specification.

## Source-to-gameplay connections

| NASA/JPL subject | Information represented | Gameplay connection |
|---|---|---|
| Mars 2020 science objectives | Perseverance's science goals and search for evidence relevant to ancient habitability and sample caching. | Campaign zones, mission goals and science priorities. |
| Mars 2020 science instruments | Roles of Mastcam-Z, SuperCam, PIXL, SHERLOC, RIMFAX, MEDA and MOXIE. | Instrument selection and the kinds of observations available to the player. |
| Rover components | Mobility, power, robotic arm, communications and other rover subsystems. | Rover workshop, component compatibility and operational capabilities. |
| Mars rock samples | Perseverance's documented sample collection and context. | Science Library sample references and player sample records. |
| First sample attempt | Perseverance's first coring attempt produced an empty tube when the target rock did not behave as expected. | A sample-failure story/event that introduces uncertainty and the need to reassess. |
| Mars communications | UHF relay through orbiters and direct-to-Earth X-band communications. | Orbiter communication opportunities, data storage and transmission decisions. |
| Mars 2020 landing | Entry, descent and landing sequence and communications context. | Simplified launch/transit/landing sequence and mission events. |

## Real information versus game model

The project keeps these categories distinct:

- **NASA/JPL information:** sourced facts and mission descriptions presented with references in the Science Library.
- **Game parameters:** component mass, power, credits, scores, battery capacity, memory, communication rates, mission timing, launch scenarios and landing outcomes. These values support gameplay balance and education; they are not NASA engineering specifications.
- **Fiction:** Dr. Owen, the player's team and rover, the mission narrative and fictional rocks/samples.

The source code comments in `scripts/data.gd` describe the provenance of the component catalogue and the separate `MODEL` and `REAL_LINK` values.

## Model limitations

2Mars does not calculate real orbital trajectories or Delta-V, does not reproduce a complete Mars 2020 flight architecture, and does not load live NASA APIs or planetary datasets. Launch windows, travel duration, landing and communication timing are simplified educational mechanics.

## References

- [NASA resources used in 2Mars](../../../research/NASA_RESOURCES_USED.md)
- [V5 mission-planning sources](research/PLANNING_SOURCES_V5.md)
- [V5 resource audit](RESOURCE_AUDIT.md)

The in-game Science Library and the linked NASA/JPL pages should be used to verify individual facts. NASA has not confirmed life on Mars; 2Mars does not claim otherwise.
