# 2Mars --- Scientific Sources for Mars Mission Planning

**Research and scientific traceability document**\
**Review date:** November 15, 2026\
**Project:** 2Mars --- NASA Space Apps Challenge 2026\
**Scope:** launch vehicle, mass, launch window, interplanetary
trajectory, and destination/landing-site selection.

------------------------------------------------------------------------

## 1. Purpose

This document compiles primary sources from NASA and NASA/JPL to support
a proposed improvement to 2Mars: a space-planning module connecting
decisions about the launch vehicle, spacecraft mass, launch window,
Earth--Mars trajectory, and scientific destination.

The goal is not to build a high-fidelity astrodynamics simulator. It is
to implement a simplified educational representation that teaches real
relationships between engineering decisions and mission constraints,
without attributing physical accuracy to calculations the game does not
perform.

**Traceability rule:** every figure presented as a real-world fact must
be traceable to an identifiable source. Values created for game
balancing must be labeled as *simulation values* or *game parameters*,
not as NASA specifications.

## 2. Verified findings

### 2.1 Launch vehicle selection, mass, and launch date are related

The Mars 2020 mission carried the Perseverance rover and Ingenuity
helicopter inside the spacecraft. The spacecraft launched on July 30,
2020, aboard a United Launch Alliance Atlas V 541 launch vehicle.

NASA/JPL explains that the available launch date range depended, among
other factors, on: - the relative orbital cadence of Earth and Mars; -
the launch vehicle's lift capability; - the spacecraft's mass; - the
desired geometry and timing for landing on Mars.

**Valid implication for 2Mars:** the launch vehicle, transported mass,
and launch opportunity should not be presented as entirely independent
decisions.

**Source limitation:** this page documents the launch vehicle used for
Mars 2020 and the factors considered for that mission. It does not
establish a general payload-capacity table for all launch vehicles, nor
does it by itself establish the exact capacity of a launch vehicle for
every orbit or trajectory.

Source: - NASA/JPL, *Mars 2020 Perseverance Landing Press Kit ---
Mission Overview*:\
https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/

### 2.2 The relevant mass is not just the rover's mass

NASA's Mars 2020 launch documentation identifies several spacecraft
elements: the rover, cruise stage, aeroshell (backshell and heat
shield), and descent stage. The mission also carried Ingenuity.

NASA's educational chapter on launches explains the effect of the rocket
equation and uses Curiosity as an example to show that the mass of the
scientific instruments is only part of the total mass of the system that
must be sent to Mars. In that example, NASA distinguishes the rover's
mass from the total payload mass, which includes the cruise stage and
the components required for landing.

**Valid implication for 2Mars:** the mass calculation should account for
a simplified mission stack---for example, rover + cruise/entry/descent
systems + any other elements included in the model---instead of treating
the rover's mass as the entire transported payload.

**Source limitation:** the Curiosity example must not be reused as a
Perseverance specification or as an Atlas V capacity figure. The payload
mass must also not be confused with the total mass of the fully fueled
launch vehicle.

Source: - NASA Science, *Basics of Space Flight --- Chapter 14:
Launch*:\
https://science.nasa.gov/learn/basics-of-space-flight/chapter14-1/

### 2.3 Mars launch opportunities are periodic, but should not be represented as one universal fixed date

NASA/JPL explains that Earth catches up with Mars approximately every 26
months and that launch opportunities to Mars occur at a similar
frequency, when planetary geometry allows a relatively short transfer.

NASA's educational material on trajectories describes a minimum-energy
transfer opportunity approximately every 25 months. The difference
between "approximately 25" and "approximately 26" reflects the
approximate nature of these explanations; it should not be turned into
an exact calendar rule.

NASA/JPL also distinguishes: - **Launch period:** the range of days
during which a launch can take place to reach the mission's target. -
**Launch window:** the interval within a particular day during which the
vehicle must lift off to meet the mission objective.

The Mars 2020 case illustrates that daily opportunities changed during
the launch period.

**Valid implication for 2Mars:** the game can present launch windows or
launch opportunities and explain that they depend on Earth--Mars
geometry and mission requirements. It should not imply that every day
offers equivalent conditions.

**Source limitation:** the approximate periodicity is not sufficient to
calculate exact future launch dates without a model of planetary
positions and mission constraints. Real launch dates must not be
invented based only on the 25--26-month rule.

Sources: - NASA/JPL, *Mars 2020 Perseverance Landing Press Kit ---
Mission Overview*:\
https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/ -
NASA Science, *Basics of Space Flight --- Chapter 4: Trajectories*:\
https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/ -
NASA/JPL, *Mars 2020 Perseverance Launch Press Kit --- Mission Overview*
(launch-period/window definitions and example):\
https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/

### 2.4 Trajectory affects propellant, transfer energy, and flight time

NASA explains that interplanetary trajectories differ in their
propellant requirements. The chapter on trajectories describes a Hohmann
transfer as a low-energy transfer between approximately circular orbits,
and explains that a spacecraft must enter the trajectory at the correct
time so Mars reaches the encounter point as the spacecraft arrives.

NASA Ames describes its *Trajectory Browser* as a resource for exploring
trajectories to planets and small bodies. The page states that the tool
provides launch dates, flight times, and Delta-V requirements, and
allows users to search for trajectories subject to launch-window,
mission-duration, and Delta-V-capability constraints.

**Valid implication for 2Mars:** it is reasonable to teach that
different trajectory options can involve different flight times and
energy/Delta-V requirements. These relationships should be represented
through predefined scenarios or source-calculated data, not arbitrary
numbers presented as real orbital results.

**Source limitation:** a Hohmann transfer is an idealized model and does
not, by itself, describe every detail of a real Mars mission. Actual
missions may include additional constraints, trajectory corrections,
arrival requirements, navigation, communications, and landing. The game
must not claim to calculate a real Hohmann transfer if it only lets
players select predefined profiles.

Sources: - NASA Science, *Basics of Space Flight --- Chapter 4:
Trajectories*:\
https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/ - NASA
Ames, *Flight Dynamics*:\
https://www.nasa.gov/ames-engineering/spaceflight-division/flight-dynamics/

### 2.5 A real example of travel time and distance

For Perseverance's July 30, 2020 launch, NASA/JPL reports: - travel
time: **203 days**; - distance traveled between Earth and Mars:
approximately **471 million kilometers**; - arrival and landing:
February 18, 2021.

These figures belong to that specific mission and launch opportunity.
They are not universal constants and must not be used as the mandatory
duration for every Mars trajectory.

**Recommended use in 2Mars:** use them as a real-world reference case or
comparison in the science library, not as an automatic result for every
configuration.

Source: - NASA/JPL, *Mars 2020 Perseverance Landing Press Kit --- Quick
Facts*:\
https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/quick_facts/

### 2.6 Destination selection should balance science and operational feasibility

The Mars 2020 landing-site selection document explains that the team
evaluated different landing sites and sought to optimize several
factors, including: - the value of in-situ scientific investigations; -
the potential to obtain a scientifically valuable sample collection; -
investigation of signs of ancient life and of geological, climatic, and
planetary history; - efficiency of science and engineering operations; -
driving distance; - terrain trafficability; - extreme temperatures.

The document notes that extreme temperatures can limit the time
available for driving and using instruments under optimal conditions.

**Valid implication for 2Mars:** site selection should not depend
exclusively on scientific interest. It can involve trade-offs between
scientific value and operational difficulty.

**Source limitation:** these criteria come from the Mars 2020
landing-site selection process. They are not a universal formula or an
official score that can automatically be applied to every location on
Mars.

Source: - NASA/JPL, *Mars 2020 Landing Site Down-Select* (project
document, February 13, 2017):\
https://marsnext.jpl.nasa.gov/documents/Mars%202020%20landing%20site%20down-select%20Feb%202017.pdf

### 2.7 Scientific objectives should influence site selection and equipment

NASA lists four main scientific objectives for Perseverance: geology,
astrobiology, sample caching, and preparation for human exploration. The
mission studies Jezero's rocks and landscape, investigates ancient
potentially habitable environments, and collects samples for a possible
future return.

**Valid implication for 2Mars:** selected scientific objectives should
be consistent with the destination and with the instruments/equipment
installed on the rover. Choosing a site should make scientific sense,
rather than being a purely aesthetic choice.

**Source limitation:** Perseverance's objectives are the objectives of
that specific mission. If 2Mars offers fictional or additional
objectives, they must be identified as educational content designed for
the game.

Source: - NASA Science, *Perseverance Science Objectives*:\
https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/

------------------------------------------------------------------------

## 3. Traceability matrix for 2Mars mechanics

  -----------------------------------------------------------------------
  Proposed mechanic Documentary basis What the game can What it must not
                                      teach             claim
  ----------------- ----------------- ----------------- -----------------
  Launch vehicle    NASA/JPL Mars     Launch-vehicle    That a simplified
  selection         2020 Mission      lift capability   payload limit is
                    Overview          is a mission      a real
                                      constraint        specification
                                                        without a
                                                        specific
                                                        technical source

  Mass budget       NASA Chapter 14;  The rover is only That rover mass
                    Mars 2020         one part of the   equals the total
                    spacecraft        system sent to    payload mass
                    components        Mars              

  Launch window     NASA/JPL Mars     Earth--Mars       That the
                    2020 Mission      geometry          25--26-month
                    Overview; NASA    constrains launch interval alone
                    Chapter 4         opportunities     gives exact dates

  Trajectory        NASA Chapter 4;   Trajectories can  That arbitrary
                    NASA Ames Flight  differ in flight  profiles are
                    Dynamics          time and Delta-V  calculated
                                                        orbital
                                                        trajectories

  Flight duration   NASA/JPL          Perseverance took That every Mars
                    Perseverance      203 days on its   mission takes 203
                    Quick Facts       specific          days
                                      trajectory        

  Site selection    NASA/JPL Landing  Scientific value  That Mars 2020
                    Site Down-Select  and operational   selection
                                      feasibility       criteria form a
                                      should be         universal scoring
                                      balanced          formula

  Scientific        NASA Perseverance Connect           That
  objectives        Science           objectives,       Perseverance's
                    Objectives        destination, and  objectives
                                      instruments       represent every
                                                        possible mission
  -----------------------------------------------------------------------

## 4. Recommended implementation requirements

The following are **design recommendations for 2Mars**, derived from the
sources above. They are not official NASA requirements.

### 4.1 Launch vehicle and mass

-   Offer clearly identified launch-vehicle options.
-   Display the payload capacity used by the game and the mass of the
    selected payload.
-   Calculate the mass of the mission stack that the game model
    considers transported.
-   Block or warn about a configuration that exceeds the defined payload
    limit.
-   If real launch vehicles are used, document the exact technical
    source and reference conditions for each capacity. Capacity depends
    on configuration and orbital destination; do not use a single value
    without context.
-   If comparable, verifiable data are unavailable, use fictional
    vehicles and label their capacities as simulation values.

### 4.2 Launch window

-   Present an opportunity period and launch options.
-   Visually explain that the relative positions of Earth and Mars
    constrain the opportunity.
-   Do not generate real dates using a fixed 26-month rule.
-   If real dates are implemented, use verifiable ephemerides or
    trajectory data and document the method.

### 4.3 Trajectory

-   Offer predefined educational profiles, for example, profiles with
    different durations and Delta-V requirements.
-   Clearly indicate whether these profiles are reference data, outputs
    from a design tool, or fictional balancing values.
-   Avoid labeling a trajectory "more efficient" without defining what
    is being optimized: propellant, Delta-V, duration, arrival
    conditions, or another criterion.
-   If the game does not solve orbital dynamics, describe the feature as
    trajectory-profile selection, not orbital simulation.

### 4.4 Destination and landing

-   Connect the destination to the scientific objectives.
-   Show operational factors supported by the documentation:
    trafficability, driving distance, and thermal conditions.
-   Distinguish scientific site evaluation from landing-safety
    evaluation. They are related, but they are not the same decision.
-   If difficulty scores are assigned, label them as a simplified game
    model.

### 4.5 Integration with the current game flow

Planning should feed into the later stages of the game: 1. Briefing and
scientific objectives. 2. Destination/landing-site selection. 3.
Launch-opportunity selection. 4. Trajectory-profile selection. 5.
Launch-vehicle selection and mass verification. 6. Final rover design
and compatibility validation. 7. Launch, cruise, arrival, and landing.

The exact interface order may vary. What matters is that the decisions
are connected and their consequences persist throughout the mission.

------------------------------------------------------------------------

## 5. Reference data that can be safely incorporated

  ------------------------------------------------------------------------
  Data                  Documented value Context and      Source
                                         caution          
  ---------------- --------------------- ---------------- ----------------
  Mars 2020 launch       ULA Atlas V 541 Vehicle used by  NASA/JPL Mission
  vehicle                                the Perseverance Overview
                                         mission          

  Launch date              July 30, 2020 Actual Mars 2020 NASA/JPL Mission
                                         launch date      Overview

  Travel time                   203 days Specific         NASA/JPL Quick
                                         Perseverance     Facts
                                         trajectory       
                                         launched July    
                                         30, 2020         

  Distance              \~471 million km Specific         NASA/JPL Quick
  traveled                               Perseverance     Facts
                                         trajectory       

  Opportunity       Approximately 25--26 General          NASA Chapter 4
  cadence                         months description; not and NASA/JPL
                                         an exact         Mission Overview
                                         calendar         

  Perseverance             Jezero Crater Site selected    NASA/JPL Mission
  landing target                         for Mars 2020    Overview

  Site-selection    Science, operational Criteria         NASA/JPL Landing
  factors            efficiency, driving discussed in the Site Down-Select
                               distance, Mars 2020        
                     trafficability, and selection        
                    extreme temperatures process          
  ------------------------------------------------------------------------

**No numerical Atlas V 541 payload capacity is included.** The sources
verified in this document confirm that this launch vehicle was used and
that its lift capability was a planning factor, but a capacity figure
under a specific orbital condition has not been validated here. Do not
add a figure without a primary technical datasheet specifying the
configuration and destination.

**No real launch-vehicle cost is included.** No comparable primary
source has been identified here that would support assigning launch
costs to the game's options. Any cost used for balancing must be labeled
as a fictional/simulation parameter.

------------------------------------------------------------------------

## 6. Short glossary

-   **Payload:** items that a launch vehicle places on the intended
    trajectory or orbit. The exact scope depends on how the mission is
    defined; 2Mars must specify which components its calculation
    includes.
-   **Lift capability:** the ability of a launch vehicle to transport a
    payload to a given destination/orbit under specified conditions. It
    is not a universal number independent of destination.
-   **Launch window:** the time interval during which a launch must
    occur to meet a mission objective.
-   **Launch period:** the range of days during which launch
    opportunities exist for the mission target.
-   **Interplanetary trajectory:** the path followed by a spacecraft
    between planets.
-   **Hohmann transfer:** an idealized low-energy transfer between
    approximately circular orbits.
-   **Delta-V (ΔV):** the change in velocity required by a maneuver or
    set of maneuvers; it is used as an indicator of propulsion demand,
    although by itself it does not equal a universal amount of fuel.
-   **Ephemerides:** data describing the positions and motions of
    celestial bodies over time.

------------------------------------------------------------------------

## 7. Primary bibliography

1.  **NASA/JPL.** *Mars 2020 Perseverance Landing Press Kit --- Mission
    Overview.*\
    https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/\
    Accessed: November 15, 2026.

2.  **NASA/JPL.** *Mars 2020 Perseverance Landing Press Kit --- Quick
    Facts.*\
    https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/quick_facts/\
    Accessed: November 15, 2026.

3.  **NASA Science.** *Basics of Space Flight --- Chapter 4:
    Trajectories.*\
    https://science.nasa.gov/learn/basics-of-space-flight/chapter4-1/\
    Accessed: November 15, 2026.

4.  **NASA Science.** *Basics of Space Flight --- Chapter 14: Launch.*\
    https://science.nasa.gov/learn/basics-of-space-flight/chapter14-1/\
    Accessed: November 15, 2026.

5.  **NASA Ames Research Center.** *Flight Dynamics --- Trajectory
    Browser.*\
    https://www.nasa.gov/ames-engineering/spaceflight-division/flight-dynamics/\
    Accessed: November 15, 2026.

6.  **NASA/JPL.** *Mars 2020 Perseverance Launch Press Kit --- Mission
    Overview.*\
    https://www.jpl.nasa.gov/news/press_kits/mars_2020/launch/mission/\
    Accessed: November 15, 2026.

7.  **NASA/JPL.** *Mars 2020 Landing Site Down-Select.* Project
    document, February 13, 2017.\
    https://marsnext.jpl.nasa.gov/documents/Mars%202020%20landing%20site%20down-select%20Feb%202017.pdf\
    Accessed: November 15, 2026.

8.  **NASA Science.** *Perseverance Science Objectives.*\
    https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/\
    Accessed: November 15, 2026.

------------------------------------------------------------------------

## 8. Usage and accuracy note

This document is a synthesis of the linked primary sources, not a
certification that any particular 2Mars implementation is a real mission
simulator. Before publishing additional numerical data---especially
launch-vehicle capacities, stage masses, Delta-V, future dates, arrival
velocities, or costs---the specific technical source, units,
configuration, and reference conditions must be verified.

Whenever 2Mars uses simplifications, the interface, documentation, and
Dr. Owen's dialogue should explicitly call them a *simplified model*,
*educational profile*, or *simulation value*. This preserves the
distinction between documented science and video-game balancing.
