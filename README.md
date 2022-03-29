# scheduler
A timetable sifter to select a clash-free combinations, with user-preference consideration.

Features:
- There are several preference presets to pick from: prioritize morning classes, prioritize evening classes, prioritize least days on campus, prioritize lunch breaks ...

Limit:
- Data must be stored locally pre-processed into correct format before being read
- CLI for sifting process

Usage:
- "main" is the source code, written in Ruby.
- "scheduler" holds the main logic of sifting timetable and taking in user preference.
- "timetableGUI" takes the output written to disk from "scheduler" and displays visually on screen.
- "timeslot" holds a custom-written date/string parser in the correct format (ddd-hh-mm).

Possible future update:
- A GUI interface from start to finish
- An automated pipeline to abstract entire class-registry process with a simple click