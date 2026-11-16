# 2Mars and the NASA Space Apps judging criteria

Evidence-based notes for the team's submission. No scores are claimed here: judges assign them.
Developed in several sessions during November 14 and 15.

## Impact
- **Problem addressed:** mission design is usually taught as facts. 2Mars lets a 15-year-old feel why a rover cannot carry everything.
- **Evidence in the build:** a first-time tutorial that completes on real actions; English and Spanish; mouse-only, keyboard-only or both; reduced-motion option; local co-op for classrooms with one computer.
- **Playtesting evidence:** team members have manually played complete game sessions. This is internal functional playtesting, not an external study. No learning outcomes have been measured with students outside the team.

## Creativity
- One loop that joins **mission design, rover operations and planetary science**: the rover you build is the rover you drive, and the debrief traces the result back to the design.
- The "failed sample" event turns a real setback (Perseverance's first coring attempt, 2021) into a lesson instead of a penalty.
- Interpretation questions reward the right level of certainty, not the most exciting answer.

## Validity
- Runs in Godot 4.7 with no plugins. 188 automated checks pass in English and Spanish, played under the normal rules by a bot.
- Power in W, stored energy in Wh and data in MB are kept consistent; generation and consumption are never mixed.
- Real NASA facts are shown apart from game values, each with its source. Game values are labelled as a model.
- **Limits:** the automated bot supports repeatable regression testing and the team has completed manual full-game playtests; however, no systematic external balance study or educational-impact evaluation has been conducted. The landing is a simplified model. Controller input is mapped but untested.

## Relevance
- Challenge: Space Mission Design Game. The player defines objectives, plans, designs, launches, operates and evaluates a mission.
- NASA information drives mechanics, not decoration: the four science objectives are the four zones; instrument capabilities decide which evidence is reachable; relay and direct link rates explain why data must wait for an orbiter; the sample catalogue shapes how samples are documented.
- The in-game library has a "NASA → game" tab with the chain source → information → mechanic → decision → consequence.

## Presentation
- The submission needs a 30-second video or a 7-slide deck, in English or with English subtitles, and every external resource listed in the References field. Check the current rules on the Space Apps site before submitting.
- The game's flow gives the demo its story: brief → design → readiness → launch → landing → science → transmit → debrief.
- **Correct before recording:** the video scripts say the game uses open NASA data "from Curiosity and InSight". The game cites Mars 2020 Perseverance sources; Curiosity appears only in an optional story.

## References to list in the submission
Mars 2020 Perseverance pages (Science Objectives, Science Instruments, Rover Components, Mars Rock Samples); NASA "Assessing Perseverance's First Sample Attempt"; NASA Glenn "Mars Perseverance Communications" (NTRS 20210010148); NASA/JPL Mars 2020 Landing Press Kit; Godot Engine; Fredoka and Nunito fonts (SIL OFL). Add any AI tools the team used, as the rules require.
