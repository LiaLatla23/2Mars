# 2Mars 🚀

**Every decision shapes the mission.**

2Mars is an interactive Mars mission design and management game developed by Team SpaceNuts for the **NASA Space Apps Challenge 2026 — Space Mission Design Game**. Built with Godot Engine 4.7 and GDScript, it introduces players to the connected scientific and engineering decisions behind a robotic mission to Mars.

Rather than focusing only on driving a rover, 2Mars follows a mission from planning and configuration through launch, interplanetary transit, landing, and surface operations. Players must consider how mission objectives, spacecraft and rover configuration, mass, power, communications, mobility, scientific instruments, and available resources affect what the mission can accomplish.

## Project at a glance

- **Genre:** Educational mission-design and management game
- **Engine:** Godot Engine 4.7
- **Language:** GDScript
- **Platforms:** Browser-based web build
- **Languages:** English and Spanish
- **Modes:** Campaign and Sandbox
- **Multiplayer:** Local two-player cooperative mode with complementary mission roles
- **Primary exploration setting:** Jezero Crater, Mars

## How to play

Players take part in the work of a Mars mission team. They define scientific priorities, make planning decisions, configure a rover, and manage the consequences of those choices throughout the mission.

The experience includes:

- **Mission planning:** Set objectives and consider mission constraints before launch.
- **Spacecraft and rover configuration:** Select components and scientific instruments while balancing mass, budget, power, mobility, and mission capability.
- **Launch and transit:** Progress through launch, cruise, communication events, and the simplified entry, descent, and landing sequence.
- **Surface operations:** Explore Martian regions, investigate scientific targets, manage rover resources, collect and document samples, and review mission results.
- **Campaign and Sandbox:** Follow a guided mission progression or experiment with mission configurations.
- **Local cooperative play:** Two players take complementary roles—Mission Commander and Rover Engineer & Scientist—so they coordinate different responsibilities.
- **Science Library:** Consult explanations, real mission examples, sources, and notes distinguishing NASA facts from game abstractions.

The game includes four campaign exploration areas, approximately 30 rover component options, and seven primary science-instrument choices. Gameplay systems simplify complex mission engineering for accessibility; they are not a professional mission-design tool or a high-fidelity orbital simulator.

## Scientific foundation

NASA and NASA/JPL mission documentation—especially material about the Mars 2020 Perseverance mission—informs the game's scientific objectives, instruments, rover systems, sample collection, mobility, power, communications, and mission stories.

These references are connected to gameplay decisions in the in-game Science Library and documented in the repository:

- [NASA resources used in 2Mars](research/NASA_RESOURCES_USED.md)
- [Scientific traceability: source to gameplay](Game-versions/V4/docs/SCIENCE_TRACEABILITY.md)
- [V4 resource and attribution audit](Game-versions/V4/docs/RESOURCE_AUDIT.md)
- [Research and resources index](research/README.md)

**Important distinction:** the project uses NASA/JPL documentation as research references. The game does not directly load NASA planetary datasets or reproduce a complete real-world astrodynamics model. Numerical values, mission durations, resource limits, and some system behaviors are simplified game parameters unless explicitly identified and sourced as real mission facts.

## Technology and production

- **Godot Engine 4.7** and **GDScript** — game engine and gameplay implementation.
- **GitHub** — source control and project documentation.
- **Vercel** — hosting for the exported browser build.
- **Canva, Claude, ChatGPT, OpenAI Codex, Microsoft Copilot, and Higgsfield** — used in different parts of the team's visual development, coding assistance, research organization, and animation workflow. Specific contributions and attribution are documented in the project submission materials and V4 resource audit.

## Team

Developed by **Team SpaceNuts** for the NASA Space Apps Challenge 2026.

## Repository structure

- `Game-versions/` — game versions and their associated project files.
- `research/` — scientific and technical research, references, and inventories.
- `Game-versions/V4/docs/` — V4 scientific traceability and resource audit.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

*2Mars — Every decision shapes the mission.*
