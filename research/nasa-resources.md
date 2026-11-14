# NASA Research & Technical References

This document presents scientific and technical findings from NASA missions and resources that inform the development of **ToMars**.

Unlike the source inventory, which records where information was found, this document focuses on the information itself: how Mars rovers work, what they investigate, which technologies they use, and how mission engineering influences exploration.

The Mars 2020 Perseverance mission serves as a primary reference because it demonstrates the operation of a robotic rover on the Martian surface.

---

## 1. Mars 2020: Perseverance Mission

### 1.1 Mission Overview

NASA's Mars 2020 mission was designed to investigate the geology and past habitability of Mars, search for potential signs of ancient microbial life, collect and cache samples, and test technologies relevant to future human exploration.

The Perseverance rover landed in Jezero Crater on February 18, 2021.

Jezero Crater was selected because geological evidence indicates that it once contained a lake and an ancient river delta. These environments make it an important location for studying Mars' geological history and investigating whether conditions could once have supported microbial life.

**Relevance to ToMars:**

Perseverance provides a real-world example of a robotic surface exploration mission. Its objectives and operations can inform the game's mission structure, exploration activities, scientific investigations, and sample collection mechanics.

### 1.2 Scientific Objectives

Perseverance has four main science objectives:

**1. Geology**

Study the rocks and landscape of Jezero Crater to understand the region's geological history, including the processes that formed and modified its surface.

**2. Astrobiology**

Assess whether ancient Martian environments could have supported microbial life and investigate materials that may preserve potential biosignatures.

NASA has not confirmed the existence of past or present life on Mars. The mission investigates evidence that could help answer this scientific question.

**3. Sample Caching**

Collect, document, and store scientifically valuable samples of Martian rock and regolith. These samples may support future investigations on Earth.

**4. Preparation for Human Exploration**

Test technologies and study environmental conditions that could be relevant to future human missions, including oxygen production, atmospheric dust, weather, and landing technologies.

**Relevance to ToMars:**

These objectives provide a foundation for the game's four exploration areas. Each area can introduce different scientific tasks and require the player to use the rover's systems and instruments for specific purposes.

---

## 2. Rover Architecture and Technology

### 2.1 Main Structure

Perseverance is a robotic laboratory designed to operate autonomously and under commands from mission operators on Earth.

Its body protects internal electronic and mechanical systems. It also supports the rover's scientific equipment, cameras, antennas, robotic arm, and mobility system.

The rover's architecture combines several interconnected subsystems:

- Structure and thermal protection.
- Mobility and suspension.
- Power generation and storage.
- Onboard computing.
- Navigation and engineering cameras.
- Scientific instruments.
- Robotic arm and sample handling.
- Communication systems.

**Relevance to ToMars:**

The rover customization system can introduce these subsystems as separate engineering categories. Players can learn that a rover is an integrated system rather than a collection of independent components.

### 2.2 Mobility System

Perseverance uses six wheels and a rocker-bogie suspension system.

This suspension allows the rover to navigate uneven terrain while maintaining contact with the surface. Its wheels are designed for movement over rocky and irregular Martian landscapes.

Mobility is important because the rover must reach scientific targets without compromising its ability to continue operating.

**Relevance to ToMars:**

This system can inspire terrain navigation, obstacle avoidance, route planning, and mobility-related decisions.

Possible gameplay considerations include:

- Terrain difficulty.
- Rover stability.
- Wheel condition.
- Route length.
- Energy consumption during movement.

These gameplay variables should be treated as simplified simulations rather than exact replicas of Perseverance's engineering models.

### 2.3 Robotic Arm

Perseverance has a robotic arm approximately 2.1 meters long, with five degrees of freedom.

The arm carries a turret equipped with scientific tools and instruments. It allows the rover to examine rocks, obtain close-up observations, perform surface abrasion, and collect samples.

The arm functions as an extension of the rover's scientific capabilities.

**Relevance to ToMars:**

The robotic arm can inspire interactive scientific activities, such as positioning an instrument, examining a rock, and collecting a sample.

The player should understand that sample collection requires selecting and investigating a scientifically relevant target.

### 2.4 Onboard Computing

Perseverance contains two identical Rover Compute Elements (RCEs), providing redundancy in its computing system.

Its onboard computers manage rover functions, communicate with instruments, monitor engineering conditions, and process mission commands and data.

The rover also uses sensors to estimate its position and orientation, supporting navigation and safe movement.

**Relevance to ToMars:**

Computing and navigation can be represented through rover status indicators, operational decisions, and mission monitoring systems.

---

## 3. Power and Energy Management

A rover operating on Mars must manage its available energy to support movement, scientific instruments, communication, and internal systems.

Perseverance uses a Multi-Mission Radioisotope Thermoelectric Generator (MMRTG). It converts heat produced by the natural radioactive decay of plutonium-238 into electrical energy.

The rover also has rechargeable lithium-ion batteries that help supply energy when demand is higher.

This is different from relying on a conventional replaceable battery as the primary energy source.

**Relevance to ToMars:**

Energy management can be a central part of the mission design and operations stages.

Possible gameplay applications:

- Estimate the energy required by planned activities.
- Consider the energy demands of scientific instruments.
- Balance movement and scientific investigations.
- Monitor available energy during rover operations.
- Evaluate whether the selected configuration supports mission objectives.

**Gameplay simplification:**

ToMars may use a simplified energy system with numerical capacity and consumption values. These values should be identified as game mechanics, not presented as exact Perseverance specifications.

---

## 4. Communication Systems

Perseverance communicates with Earth directly and through spacecraft orbiting Mars.

The rover uses UHF communication links to relay data through Mars orbiters. It also has X-band communication systems for communication with Earth.

Communication is essential because mission operators need information about the rover's condition, scientific observations, and exploration activities.

Data collected by the rover must be stored and transmitted to be received by the mission team.

**Relevance to ToMars:**

Communication can become an operational resource in the game.

Possible gameplay applications:

- Collect scientific data in different locations.
- Store data onboard the rover.
- Evaluate communication availability.
- Transmit collected information when a suitable connection is available.
- Include successfully transmitted science data in the mission debrief.

This can help players understand the difference between collecting scientific information and successfully transmitting it.

---

## 5. Scientific Instruments

Perseverance carries seven primary science instruments. Together, they investigate Martian geology, chemistry, atmosphere, environmental conditions, and potential biosignatures.

| Instrument | Main function | Possible application in ToMars |
|---|---|---|
| Mastcam-Z | Zoom cameras for imaging and geological observations. | Identify and inspect distant targets. |
| SuperCam | Uses laser, imaging, and spectroscopic techniques to investigate materials. | Perform remote rock analysis. |
| PIXL | Uses X-ray spectroscopy to identify chemical elements in rocks and soil. | Investigate elemental composition. |
| SHERLOC | Uses Raman and fluorescence spectroscopy to investigate minerals and organic compounds. | Examine materials relevant to astrobiology. |
| MEDA | Measures atmospheric and environmental conditions. | Monitor weather and environmental data. |
| RIMFAX | Uses ground-penetrating radar to investigate subsurface structures. | Explore underground geological features. |
| MOXIE | Demonstrated oxygen production from carbon dioxide in the Martian atmosphere. | Introduce resource-utilization technology. |

**Important distinction:**

WATSON is a camera associated with the SHERLOC instrument. It is not counted as a separate one of the seven primary science instruments.

MOXIE was a technology demonstration, not a complete life-support system.

**Relevance to ToMars:**

Each instrument can provide a different type of scientific information. This makes instrument selection meaningful during mission design and encourages players to choose equipment according to their scientific objectives.

---

## 6. Scientific Exploration and Sample Collection

### 6.1 Geological Investigation

Rocks and sediments preserve information about the geological processes that shaped Mars.

By examining their composition, structure, and context, scientists can reconstruct aspects of the planet's environmental history.

Perseverance uses remote observations and contact science to investigate potential targets before selecting samples.

**Application to ToMars:**

Players can investigate geological targets, compare observations, and decide which materials are worth collecting.

### 6.2 Sample Collection

Perseverance collects rock cores and regolith samples using its drilling and sampling systems.

The sample collection process involves more than drilling:

1. Identify a scientifically interesting target.
2. Observe and characterize the material.
3. Select an appropriate sampling location.
4. Collect the sample.
5. Seal and document the sample.
6. Store it for potential future retrieval.

Sample context is important because scientists need to know where the material came from and what geological features surrounded it.

**Application to ToMars:**

A sample should have scientific value beyond simply being an item collected by the player. Its location, geological context, and observations should contribute to the mission's scientific record.

### 6.3 Planetary Protection and Contamination

Sample integrity is important in planetary science.

Materials brought from Earth or introduced during sampling could affect scientific investigations. Perseverance's sample system was designed with contamination control in mind.

**Application to ToMars:**

The game can introduce sample-handling procedures and reward careful documentation and correct scientific practices.

---

## 7. Engineering Decisions and Mission Trade-offs

Space missions require decisions that balance scientific goals, engineering limitations, and available resources.

A system that improves one capability may introduce additional requirements or limitations elsewhere.

Examples of engineering considerations include:

| Engineering factor | Mission consideration |
|---|---|
| Mass | Components contribute to the total rover mass and mission constraints. |
| Power | Systems and instruments require energy to operate. |
| Communications | Data transmission depends on available communication systems and opportunities. |
| Instruments | Equipment determines which scientific investigations can be performed. |
| Mobility | Rover configuration and terrain influence exploration capabilities. |
| Storage | Scientific observations and engineering data require onboard storage. |

**Application to ToMars:**

The mission design stage can ask players to balance these factors before operating their rover.

The goal is not to create one universally perfect configuration, but to encourage players to make decisions that support their chosen mission objectives.

---

## 8. Translating NASA Research into Gameplay

The following table summarizes how real mission concepts can inform ToMars.

| NASA reference | Scientific or engineering concept | Potential gameplay implementation |
|---|---|---|
| Perseverance mission objectives | Science-driven exploration | Mission objectives and exploration zones |
| Rover mobility system | Navigation across uneven terrain | Driving and route planning |
| Robotic arm | Contact science and sampling | Interactive sample collection |
| Science instruments | Different observation techniques | Instrument-based minigames |
| MMRTG and batteries | Energy generation and storage | Energy management |
| Communication systems | Data relay and transmission | Signal and data transmission mechanics |
| Sample caching | Preservation and documentation | Sample archive and mission records |
| Environmental instruments | Martian weather monitoring | Environmental hazards and status indicators |

**Scientific accuracy principle:**

ToMars is an educational game inspired by real planetary exploration missions. Its gameplay systems may simplify complex engineering processes to make them understandable and interactive.

Whenever numerical values or behaviors are simplified, they should be clearly distinguished from real NASA specifications.

---

## 9. Primary References

The following official resources support the research summarized in this document:

1. [NASA — Perseverance Science Objectives](https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/)
2. [NASA — Perseverance Rover Components](https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/)
3. [NASA — Perseverance Science Instruments](https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/)
4. [NASA — Mars 2020 Mission Overview](https://science.nasa.gov/mission/mars-2020-perseverance/)
5. [NASA JPL — Mars 2020 Science Overview](https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/science/)
6. [NASA — Mars Sample Return Science Overview](https://science.nasa.gov/mission/mars-sample-return/science/)

---

*ToMars | SpaceNuts Team | NASA Space Apps Challenge 2026*
