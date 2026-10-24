# A Life Well Played

Portrait life simulation for Godot 4.6. A generated character lives from birth to death. Daily Life and Fast Life share one simulation. Only the clock differs.

## Godot

Use Godot 4.6.3 from this machine:

`P:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe`

The console build in the same folder returns script exit codes. Use it for the checks:

`P:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe`

Open this folder in Godot (the folder that contains `project.godot`). Press Play. The window is a 360×640 portrait canvas, stretched nearest-neighbour.

## How to play

The menu has Daily Life, Fast Life, Past Lives, and Settings. An active life shows `Name — Age N` under its mode.

Daily Life: "One day. Ten years. One extraordinary life." One local calendar day unlocks one decade. Day 1 is ages 0–9, day 2 is 10–19, and so on. Finish the open decade, then the character waits until the next local midnight. Reopening the same day does not unlock another decade. Missed days unlock the missed decades in order. You still press through each one. The game never chooses for you.

Fast Life: "One lifetime. One sitting. Infinite possibilities." After a decade resolves, press **Open the next decade**. Nothing advances while you are reading or choosing.

Each life is saved after every decision. Daily and Fast use separate files. Playing one does not change the other. A finished life is archived with its mode. You cannot move a character from one mode to the other. Fast Life can start another life as soon as the current one ends. Daily Life's new life starts at birth on today's calendar day.

Death ends the life at once in both modes. The memorial only lists what was recorded.

## Debug and the simulated clock

Open **Debug** from the game screen or from Settings.

- Skip this decade picks the first visible choice, then continues. This is the only auto-decide path, and it is marked Debug.
- Force an event id, force the next outcome id, or force death.
- Restart with a seed replaces the active life and does not archive it.
- Set simulated today (Daily Life only) moves the trusted date forward and unlocks every day in between. It does not use the 14-day cap.

Clock protection, outside Debug:

- The last trusted local date is saved.
- A clock set backwards stays on that trusted day. No decade is removed and none is granted. The notice is: "The clock went backwards. Today stays put."
- A jump of more than 14 calendar days unlocks only 14 decades. The trusted date then becomes the real system date, so the extra days are not granted again on the next launch. The notice is: "The calendar jumped ahead. Only 14 decades were unlocked."
- Day 1 is already open. A huge jump on the morning of day 1 therefore leaves 15 decades playable (today, plus 14).

## Checks

```powershell
& "P:\Godot\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64_console.exe" --headless --path "S:\PROJECTS\A life well lived" --script res://tests/run_checks.gd
```

Exit 0 and the line `QA_OK` mean every check passed. The log includes one Fast Life from seed `20261024`.

## Numbers the brief left open

- Personality and hidden traits are integers from 1 to 10. Visible attributes other than wealth are 0–100. Wealth is coins from 0 to 999999. Debt is separate. Luck and stress are 0–100.
- A decade holds 2, 3, or 4 events. Story beats that must happen at a set age are reserved first, up to 4. Catch-up beats fill leftover slots.
- A life ends by mortality, by a dangerous outcome, or at age 110 of old age. Random death is off under 40 unless a serious injury or smoking flag is set. Young death comes from choices such as the bridge.
- UI text uses Godot's default font. Characters and rooms use nearest-neighbour pixel art.

## Add an event

Add a JSON file under `data/events/`, or add an object to an existing file. Each file is either an array of events or `{ "events": [ ... ] }`. No script change is required.

Fields:

- `id`, `category`, `text` (under about 30 words), `min_age`, `max_age`, `weight`
- `requires` and `excludes` for flags, relationship, children, wealth, education, and a living or dead NPC
- `choices`: 2 to 4, each with a one-sentence `label`, `effects`, optional `outcomes`, `delayed`, and `followups`
- `animation`, `background`, `once`, `fallback`
- Optional `priority` and `at_age` to reserve that birthday inside the decade
- Optional `catch_up` and `catch_at` so a missed beat can still appear later in range
- Optional `storyline` so one thread cannot fill every slot
- Optional `placeholders` such as `friend_name` or `child_name`. The event is skipped when nobody can fill them

Categories already used: childhood, education, romance, career, finance, family, social, health, adventure, crime, luck, tragedy, ageing.

A delayed row looks like `{ "due_age": 45, "chance": 0.8, "text": "...", "effects": { } }`. Chance below 1 is not guaranteed.

## Add a branching storyline

1. Give the events a shared `storyline` name.
2. Set a flag in the choice that opens the branch.
3. Put that flag in `requires.flags` on later events.
4. Point `followups` at the next event id so it is preferred while it is unresolved.
5. Gate contradictory beats with `requires` or `excludes` (no divorce while single, no business beat without the partnership).

Kathy's campus romance requires `kathy_university`, which is set only by applying to her university at the age-18 fork "You've graduated. What next?". Derek's embezzlement requires `derek_partners` and a living Derek who is not already in prison or dead.

## Replace the placeholder sprites

Sheets live in `assets/characters/`. One PNG per life stage: `baby`, `child`, `teen`, `young_adult`, `adult`, `middle_aged`, `elderly`, `very_elderly`. Frames are 32×48 in an 8-column sheet. `data/animations.json` maps animation ids to a start frame, frame count, fps, loop, and hold time (1–3 seconds).

Placeholder sheets use key colours so the game can recolour hair, skin, and eyes: skin `(255, 0, 170)`, hair `(255, 170, 0)`, eyes `(0, 229, 255)`. Set `"palette": false` in `animations.json` when a sheet is already final art and should not be recoloured. Missing files and unknown animation ids fall back instead of crashing. Rooms are `assets/backgrounds/<id>.png`. The NPC face is `assets/npcs/portrait.png`.

Regenerate the placeholders with `tools/make_art.py`. Regenerate the event JSON with `tools/build_events.py`. The game reads the JSON and PNG files, not the Python.
