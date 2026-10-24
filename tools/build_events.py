"""Write event templates and name lists. The game reads the JSON, not this file."""

import json
from pathlib import Path

ROOT = Path(r"S:\PROJECTS\A life well lived")
OUT = ROOT / "data" / "events"


def words(text: str) -> int:
    return len(text.replace("{child_name}", "Sam").replace("{friend_name}", "Derek").split())


def outcome(oid, text, weight=1, effects=None, death="", animation=""):
    row = {"id": oid, "weight": weight, "text": text, "effects": effects or {}}
    if death:
        row["death"] = death
    if animation:
        row["animation"] = animation
    return row


def choice(cid, label, effects=None, outcomes=None, **extra):
    row = {
        "id": cid,
        "label": label,
        "effects": effects or {},
        "outcomes": outcomes
        or [outcome("done", "Life carries the moment onward.")],
    }
    row.update(extra)
    return row


def ev(**kwargs):
    row = {
        "weight": 8,
        "once": True,
        "fallback": False,
        "priority": False,
        "catch_up": False,
        "storyline": "",
        "background": "home",
        "animation": "idle",
        "npc": "",
        "placeholders": [],
        "bias": {},
        "requires": {},
        "excludes": {},
        "on_present": {},
        "choices": [],
    }
    row.update(kwargs)
    return row


KATHY = {
    "id": "kathy",
    "name": "Kathy",
    "role": "crush",
    "affection": 28,
    "circumstances": "At school",
    "history": "Met Kathy.",
    "appearance": {"hair": "long", "hair_color": "auburn", "skin": "fair", "eyes": "green"},
}
DEREK = {
    "id": "derek",
    "name": "Derek",
    "role": "friend",
    "affection": 30,
    "circumstances": "Lives nearby",
    "history": "Met Derek as children.",
    "appearance": {"hair": "short", "hair_color": "black", "skin": "tan", "eyes": "brown"},
}


def pack():
    childhood = [
        ev(
            id="first_breath",
            category="childhood",
            text="The room leans in. Someone says your name like a gift.",
            min_age=0, max_age=1, at_age=0, weight=12,
            animation="idle",
            choices=[
                choice("cry", "Wail until held.", {"stats": {"happiness": 4}}, [outcome("held", "Arms arrive. The world gets warmer.", effects={"stats": {"happiness": 3}})]),
                choice("stare", "Stare at the light.", {"stats": {"intelligence": 1}}, [outcome("quiet", "You study the brightness and go quiet.")]),
            ],
        ),
        ev(
            id="first_steps",
            category="childhood",
            text="Your legs have a new idea. The floor looks far away.",
            min_age=1, max_age=3, at_age=1, weight=10,
            animation="walk",
            choices=[
                choice("toddle", "Try a wobbly step.", {"stats": {"fitness": 3}}, [outcome("step", "Two steps, then a proud sit.", animation="celebrate", effects={"stats": {"happiness": 4}})]),
                choice("carried", "Reach up to be carried.", {"stats": {"happiness": 3}}, [outcome("up", "You travel by hip, which is faster.")]),
            ],
        ),
        ev(
            id="family_supper",
            category="family",
            text="The household gathers, noisy and warm, around one table.",
            min_age=3, max_age=6, at_age=4, weight=8,
            animation="sit",
            choices=[
                choice("help", "Help set the table.", {"stats": {"happiness": 3}}, [outcome("praise", "Someone notices. It feels enormous.")]),
                choice("hide", "Hide under the table.", {"stats": {"stress": -2}}, [outcome("giggle", "Feet pass by. You giggle anyway.")]),
            ],
        ),
        ev(
            id="school_gate",
            category="education",
            text="School doors open. Everyone seems to know a secret.",
            min_age=6, max_age=8, at_age=7, weight=10,
            background="school", animation="worried",
            choices=[
                choice("enter", "Walk in without looking back.", {"stats": {"confidence": 0, "stress": 4, "charisma": 2}}, [outcome("class", "A chair has your name on a sticker.", effects={"education": "school"})]),
                choice("cling", "Cling to a parent a moment.", {"stats": {"stress": 2, "happiness": 2}}, [outcome("wave", "You wave, then you go.")]),
            ],
        ),
        ev(
            id="meet_derek",
            category="social",
            storyline="derek",
            text="A boy named Derek dares you to race to the corner.",
            min_age=8, max_age=10, at_age=9, weight=40, priority=True,
            background="school", animation="walk", npc="derek",
            on_present={"flags_set": ["met_derek"], "ensure_npc": DEREK},
            choices=[
                choice("race", "Race him and laugh.", {"stats": {"fitness": 3, "happiness": 4}, "npc_patch": {"id": "derek", "affection_delta": 8, "history": "Raced to the corner."}}, [outcome("tie", "It is a tie, which he disputes.")]),
                choice("walk", "Walk and talk instead.", {"stats": {"charisma": 3}, "npc_patch": {"id": "derek", "affection_delta": 6, "history": "Walked home together."}}, [outcome("talk", "He tells a terrible joke. You keep it.")]),
            ],
        ),
        ev(
            id="playground",
            category="childhood",
            text="The big kids hold the good swing and watch you.",
            min_age=10, max_age=12, at_age=11, weight=7,
            background="school", animation="confused",
            choices=[
                choice("share", "Ask to share the swing.", {"stats": {"charisma": 3}}, [outcome("yes", "They shrug and make room.", effects={"stats": {"happiness": 3}})]),
                choice("rough", "Play somewhere rougher.", {"stats": {"fitness": 3, "health": -2}}, [outcome("scrape", "A scraped knee, and a story.")]),
            ],
        ),
        ev(
            id="talent_show",
            category="childhood",
            text="The school show needs one more act before Friday.",
            min_age=11, max_age=13, at_age=12, weight=8, bias={"creativity": 1.0},
            background="school", animation="embarrassed",
            choices=[
                choice("perform", "Perform anyway.", {"stats": {"confidence": 0, "stress": 4}}, [outcome("cheer", "The clapping surprises you.", animation="celebrate", effects={"stats": {"happiness": 8, "charisma": 4}, "achievement": "Performed in the school show", "memorable": "Performed in the school show."})]),
                choice("watch", "Watch from the seats.", {"stats": {"happiness": 2}}, [outcome("clap", "You clap the loudest for a friend.")]),
            ],
        ),
    ]
    education = [
        ev(
            id="meet_kathy",
            category="romance",
            storyline="kathy",
            text="Kathy laughs at a joke you almost did not tell.",
            min_age=14, max_age=16, at_age=15, weight=40, priority=True,
            background="school", animation="embarrassed", npc="kathy",
            on_present={"flags_set": ["met_kathy"], "ensure_npc": KATHY},
            choices=[
                choice("joke", "Tell the rest of the joke.", {"stats": {"charisma": 3}, "npc_patch": {"id": "kathy", "name": "Kathy", "affection_delta": 10, "role": "crush", "history": "Shared a joke."}}, [outcome("laugh", "She laughs again. You keep the sound.", animation="laugh")]),
                choice("quiet", "Smile and say little.", {"stats": {"stress": 2}, "npc_patch": {"id": "kathy", "name": "Kathy", "affection_delta": 4, "role": "crush", "history": "Met quietly."}}, [outcome("nod", "She nods like she understood anyway.")]),
            ],
        ),
        ev(
            id="exam_nerves",
            category="education",
            text="Tomorrow's exam is already sitting on your chest.",
            min_age=16, max_age=17, at_age=16, weight=9,
            background="school", animation="worried",
            choices=[
                choice("study", "Study until the page blurs.", {"stats": {"stress": 6, "intelligence": 4}}, [outcome("pass", "The answers are tired, but present.")]),
                choice("sleep", "Sleep and trust the morning.", {"stats": {"stress": -4, "health": 2}}, [outcome("rested", "You wake clearer than you feared.")]),
            ],
        ),
        ev(
            id="grad_fork",
            category="education",
            storyline="education",
            text="You've graduated. What next?",
            min_age=18, max_age=18, at_age=18, weight=80, priority=True,
            background="school", animation="confused",
            choices=[
                choice(
                    "kathy_uni",
                    "Apply to Kathy's university.",
                    {
                        "flags_set": ["kathy_university", "in_university"],
                        "stats": {"happiness": 8, "stress": 6},
                        "debt": 18,
                        "education": "university",
                        "memorable": "Chose Kathy's university.",
                        "npc_patch": {"id": "kathy", "name": "Kathy", "affection_delta": 18, "role": "classmate", "history": "Chose Kathy's university.", "circumstances": "Same university", "appearance": KATHY["appearance"]},
                    },
                    [outcome("in", "You both get in. She saves you a seat.", animation="love", effects={"achievement": "Started university with Kathy", "stats": {"happiness": 4}})],
                    animation="love",
                    followups=["path_kathy"],
                ),
                choice(
                    "prestige_uni",
                    "Take the prestigious university.",
                    {
                        "flags_set": ["prestigious_university", "in_university", "family_proud"],
                        "stats": {"stress": 12, "intelligence": 4},
                        "debt": 28,
                        "education": "prestigious",
                        "memorable": "Chose a prestigious university.",
                    },
                    [outcome("hard", "The reading list weighs more than you do.", effects={"stats": {"stress": 4}})],
                    animation="worried",
                    followups=["path_prestige"],
                ),
                choice(
                    "skip_work",
                    "Skip university and work.",
                    {
                        "flags_set": ["skipped_university", "working_early"],
                        "stats": {"wealth": 20, "stress": -4},
                        "education": "apprenticeship",
                        "employment": "employed",
                        "career": "Apprentice",
                        "income": 8,
                        "memorable": "Skipped university to work.",
                    },
                    [outcome("wage", "A wage arrives early. The lectures do not.", animation="earn_money")],
                    animation="earn_money",
                    followups=["path_work"],
                ),
                choice(
                    "derek_uni",
                    "Go to Derek's university.",
                    {
                        "flags_set": ["derek_university", "in_university"],
                        "stats": {"happiness": 5, "stress": 5},
                        "debt": 14,
                        "education": "university",
                        "memorable": "Went to Derek's university.",
                        "npc_patch": {"id": "derek", "name": "Derek", "affection_delta": 16, "role": "classmate", "history": "Went to Derek's university.", "circumstances": "Same campus", "appearance": DEREK["appearance"]},
                    },
                    [outcome("dorm", "Derek throws a sheet over the spare bed.", animation="laugh", effects={"achievement": "Started university with Derek"})],
                    animation="laugh",
                    followups=["path_derek"],
                ),
            ],
        ),
        ev(
            id="path_kathy",
            category="romance",
            storyline="kathy",
            text="Kathy waves from the university gate with two coffees.",
            min_age=20, max_age=20, at_age=20, weight=30, priority=True,
            background="university", animation="love", npc="kathy",
            requires={"flags": ["kathy_university"]},
            choices=[
                choice(
                    "ask",
                    "Ask her to the spring fair.",
                    {
                        "flags_set": ["kathy_dating"],
                        "relationship_status": "dating",
                        "memorable": "Started dating Kathy.",
                        "relationship_note": "Dated Kathy.",
                        "npc_patch": {"id": "kathy", "name": "Kathy", "affection_delta": 20, "role": "partner", "history": "Started dating.", "circumstances": "Dating"},
                    },
                    [outcome("yes", "She says yes before you finish asking.", animation="love")],
                    animation="love",
                    followups=["kathy_proposal"],
                ),
                choice(
                    "friends",
                    "Keep the friendship easy.",
                    {
                        "flags_set": ["kathy_friends"],
                        "npc_patch": {"id": "kathy", "name": "Kathy", "affection_delta": 4, "role": "friend", "history": "Stayed friends at university."},
                    },
                    [outcome("easy", "The coffees stay friendly, and that is plenty.")],
                ),
            ],
        ),
        ev(
            id="path_derek",
            category="social",
            storyline="derek",
            text="Derek has a spare key and a terrible poster.",
            min_age=20, max_age=20, at_age=20, weight=30, priority=True,
            background="university", animation="laugh", npc="derek",
            requires={"flags": ["derek_university"]},
            choices=[
                choice("flat", "Share the flat with Derek.", {"flags_set": ["derek_close"], "npc_patch": {"id": "derek", "affection_delta": 12, "role": "classmate", "history": "Shared a flat.", "circumstances": "Flatmates"}}, [outcome("poster", "The poster stays. So does he.")]),
                choice("room", "Keep your own room.", {"stats": {"stress": -2}, "npc_patch": {"id": "derek", "affection_delta": 2}}, [outcome("space", "You visit, then you leave the mess.")]),
            ],
        ),
        ev(
            id="path_prestige",
            category="education",
            storyline="education",
            text="The prestigious course drops a frightening reading list.",
            min_age=20, max_age=20, at_age=20, weight=30, priority=True,
            background="university", animation="worried",
            requires={"flags": ["prestigious_university"]},
            choices=[
                choice("join", "Join the hard program.", {"flags_set": ["elite_program"], "stats": {"intelligence": 6, "stress": 8}}, [outcome("grind", "You learn quickly and sleep less.")]),
                choice("coast", "Coast and protect your sleep.", {"flags_set": ["coasting"], "stats": {"happiness": 4, "stress": -2}}, [outcome("easy", "The grades survive. Your nerves do too.")]),
            ],
        ),
        ev(
            id="path_work",
            category="career",
            storyline="career",
            text="Your first real shift starts before the sun.",
            min_age=20, max_age=20, at_age=20, weight=30, priority=True,
            background="office", animation="earn_money",
            requires={"flags": ["skipped_university"]},
            choices=[
                choice("sign", "Sign the apprenticeship.", {"flags_set": ["trade_path"], "qualification": "Apprenticeship", "career": "Apprentice", "employment": "employed", "income": 9}, [outcome("tools", "The tools fit your hands better than pens did.", effects={"achievement": "Started an apprenticeship"})]),
                choice("shifts", "Take whatever shift pays.", {"employment": "employed", "career": "Clerk", "income": 7, "stats": {"stress": 3}}, [outcome("cash", "The cash is small and on time.", animation="earn_money")]),
            ],
        ),
        ev(
            id="degree_day",
            category="education",
            storyline="education",
            text="Results day. Your name is on the pass list.",
            min_age=22, max_age=22, at_age=22, weight=40, priority=True,
            background="university", animation="celebrate",
            requires={"flags": ["in_university"]},
            excludes={"flags": ["skipped_university"]},
            choices=[
                choice("job", "Start the graduate job.", {"flags_set": ["degree"], "qualification": "University degree", "employment": "employed", "career": "Graduate", "income": 14, "achievement": "Earned a degree", "memorable": "Earned a degree."}, [outcome("desk", "A desk, a badge, and a new kind of tired.", animation="earn_money")]),
                choice("study", "Keep studying a while longer.", {"flags_set": ["degree"], "qualification": "University degree", "stats": {"intelligence": 5, "stress": 4}, "achievement": "Earned a degree"}, [outcome("more", "The library still knows your name.")]),
            ],
        ),
        ev(
            id="found_wallet",
            category="luck",
            text="A wallet sits on a bench, fat and unattended.",
            min_age=17, max_age=19, at_age=17, weight=4, bias={"kindness": 0.8},
            animation="confused",
            choices=[
                choice("return", "Hand it in.", {"stats": {"happiness": 4, "luck": 2}}, [outcome("thanks", "The owner cries in a grateful way.")]),
                choice("keep", "Keep the cash inside.", {"stats": {"wealth": 15, "stress": 6}}, [outcome("heavy", "The money is light. The feeling is not.", animation="lose_money")]),
            ],
        ),
    ]
    derek = [
        ev(
            id="business_fork",
            category="career",
            storyline="derek",
            text="Work feels small. A business could be yours.",
            min_age=24, max_age=24, at_age=24, weight=50, priority=True,
            background="office", animation="confused",
            choices=[
                choice("solo", "Quit and start a business.", {"flags_set": ["owns_business"], "employment": "self", "career": "Founder", "income": 10, "stats": {"wealth": -12, "stress": 8}, "memorable": "Started a business."}, [outcome("sign", "The sign is cheap. The hope is not.", animation="earn_money")]),
                choice("steady", "Keep the steady job.", {"employment": "employed", "income": 9, "career": "Clerk"}, [outcome("badge", "The badge still works. So do you.")]),
                choice(
                    "partner",
                    "Partner with Derek.",
                    {
                        "flags_set": ["owns_business", "derek_partners"],
                        "employment": "self",
                        "career": "Partner",
                        "income": 14,
                        "stats": {"happiness": 4},
                        "memorable": "Started a business with Derek.",
                        "relationship_note": "Business partners with Derek.",
                        "npc_patch": {"id": "derek", "name": "Derek", "affection_delta": 12, "role": "partner", "history": "Started a business together.", "circumstances": "Business partner"},
                    },
                    [outcome("keys", "You both get a key. He grins too wide.")],
                    requires={"flags": ["met_derek"], "missing_flags": ["derek_dead", "derek_in_prison"], "npc_id": "derek", "npc_alive": True},
                ),
                choice(
                    "refuse",
                    "Tell Derek no.",
                    {"flags_set": ["refused_derek"], "npc_patch": {"id": "derek", "affection_delta": -8, "history": "Turned down the partnership."}},
                    [outcome("cool", "He shrugs. The air cools a little.")],
                    requires={"flags": ["met_derek"], "missing_flags": ["derek_dead"], "npc_id": "derek", "npc_alive": True},
                ),
            ],
        ),
        ev(
            id="trade_rise",
            category="career",
            storyline="career",
            text="Your hands are faster than the new apprentices.",
            min_age=27, max_age=27, at_age=27, weight=24, priority=True,
            background="office", animation="earn_money",
            requires={"flags": ["skipped_university"]},
            choices=[
                choice("shop", "Open a shop of your own.", {"flags_set": ["owns_business", "trade_path"], "career": "Shop owner", "employment": "self", "income": 16, "housing": "apartment", "achievement": "Opened a shop", "memorable": "Opened a shop."}, [outcome("bell", "The door bell works. Customers follow.", animation="celebrate")]),
                choice("crew", "Stay on the crew and master it.", {"career": "Tradesperson", "employment": "employed", "income": 12, "qualification": "Trade certificate"}, [outcome("skill", "The hard jobs start coming to you.")]),
            ],
        ),
        ev(
            id="derek_success",
            category="finance",
            storyline="derek",
            text="The business with Derek is actually working.",
            min_age=31, max_age=31, at_age=31, weight=20, priority=True,
            background="office", animation="celebrate", npc="derek",
            requires={"flags": ["derek_partners"], "missing_flags": ["derek_partners_ended", "derek_dead", "derek_in_prison"], "npc_id": "derek", "npc_alive": True},
            choices=[
                choice("expand", "Expand the business.", {"stats": {"wealth": 40, "stress": 6}, "income_delta": 4}, [outcome("busy", "More orders. Less sleep. Better shoes.")]),
                choice("careful", "Keep it small and careful.", {"stats": {"wealth": 18, "happiness": 3}}, [outcome("steady", "The books stay boring, which is perfect.")]),
            ],
        ),
        ev(
            id="strain_marriage",
            category="family",
            storyline="kathy",
            text="Derek keeps calling. Kathy has stopped smiling about it.",
            min_age=40, max_age=40, at_age=40, weight=20, priority=True,
            background="home", animation="worried", npc="kathy",
            requires={"flags": ["kathy_married", "derek_partners"], "missing_flags": ["derek_dead", "divorced"]},
            choices=[
                choice("kathy_side", "Side with Kathy tonight.", {"stats": {"stress": -2}, "npc_patch": {"id": "kathy", "affection_delta": 8, "history": "You chose Kathy over the business call."}}, [outcome("quiet", "The phone goes unanswered. Dinner is kinder.")]),
                choice("derek_side", "Take Derek's call.", {"flags_set": ["marriage_strain"], "stats": {"stress": 6}, "npc_patch": {"id": "kathy", "affection_delta": -10, "history": "A business call ruined dinner."}}, [outcome("late", "You come back to a colder kitchen.")]),
                choice("mediate", "Ask them both for one calm talk.", {"stats": {"charisma": 3}, "npc_patch": {"id": "kathy", "affection_delta": 3}}, [outcome("truce", "It is not peace, but it is a truce.")]),
            ],
        ),
        ev(
            id="derek_embezzle",
            category="crime",
            storyline="derek",
            text="The books do not match. Derek has been skimming.",
            min_age=36, max_age=36, at_age=36, weight=30, priority=True,
            background="office", animation="angry", npc="derek",
            requires={
                "flags": ["derek_partners"],
                "missing_flags": ["derek_dead", "derek_in_prison", "derek_partners_ended"],
                "npc_id": "derek",
                "npc_alive": True,
            },
            choices=[
                choice(
                    "confront",
                    "Confront him with the books.",
                    {},
                    [
                        outcome("repay", "He pays it back and cannot meet your eye.", weight=45, effects={"flags_set": ["derek_ashamed"], "stats": {"wealth": 24}, "npc_patch": {"id": "derek", "affection_delta": -18, "history": "Repaid what he skimmed."}}),
                        outcome("prison", "You report him. Prison sticks.", weight=40, animation="cry", effects={"flags_set": ["derek_in_prison", "derek_betrayed"], "memorable": "Derek went to prison for skimming.", "npc_patch": {"id": "derek", "alive": True, "role": "inmate", "affection_delta": -30, "circumstances": "In prison", "history": "Sent to prison for skimming."}}),
                        outcome("death", "The scandal ends him. He does not return.", weight=15, animation="cry", death="", effects={"flags_set": ["derek_dead", "derek_betrayed"], "memorable": "Derek died after the embezzlement.", "npc_patch": {"id": "derek", "alive": False, "role": "lost", "circumstances": "Died after the scandal", "history": "Died after the embezzlement."}}),
                    ],
                ),
                choice("ignore", "Ignore the missing money.", {"flags_set": ["derek_betrayed"], "stats": {"wealth": -28, "stress": 8}, "npc_patch": {"id": "derek", "affection_delta": -6}}, [outcome("hole", "The hole in the books gets wider.")]),
                choice(
                    "join",
                    "Skim a little yourself.",
                    {},
                    [
                        outcome("away", "You get away with it. The flat improves.", weight=55, effects={"stats": {"wealth": 36, "stress": 8}, "flags_set": ["shady_past"]}),
                        outcome("caught", "You are both caught. Prison sticks.", weight=45, effects={"flags_set": ["in_prison", "derek_in_prison", "derek_betrayed"], "employment": "none", "career": "", "memorable": "Went to prison.", "npc_patch": {"id": "derek", "alive": True, "role": "inmate", "circumstances": "In prison"}}),
                    ],
                ),
                choice("leave", "Leave the partnership.", {"flags_set": ["derek_partners_ended"], "stats": {"stress": -3}}, [outcome("walk", "You leave the keys and the mess.")]),
            ],
        ),
        ev(
            id="prison_visit",
            category="crime",
            storyline="derek",
            text="Derek is allowed visitors on Thursdays.",
            min_age=41, max_age=50, at_age=43, weight=12,
            background="office", animation="sad" if False else "cry", npc="derek",
            requires={"flags": ["derek_in_prison"], "missing_flags": ["derek_dead"], "npc_id": "derek", "npc_alive": True},
            choices=[
                choice("visit", "Visit and listen.", {"npc_patch": {"id": "derek", "affection_delta": 6, "history": "You visited Derek in prison."}}, [outcome("glass", "The glass is thick. He still talks.")]),
                choice("cut", "Cut off contact.", {"npc_patch": {"id": "derek", "affection_delta": -15, "history": "You stopped visiting."}}, [outcome("quiet", "Thursdays become ordinary again.")]),
            ],
        ),
        ev(
            id="derek_gone",
            category="tragedy",
            storyline="derek",
            text="The news is short. Derek has died.",
            min_age=40, max_age=60, at_age=44, weight=14,
            background="home", animation="cry",
            requires={"flags": ["derek_dead"]},
            choices=[
                choice("mourn", "Mourn him properly.", {"stats": {"happiness": -6}, "memorable": "Mourned Derek."}, [outcome("name", "You say his name out loud once.")]),
                choice("silent", "Stay silent and work.", {"stats": {"stress": 5}}, [outcome("busy", "The work does not ask questions.")]),
            ],
        ),
        ev(
            id="derek_reconcile",
            category="social",
            storyline="derek",
            text="Derek asks for a talk you both avoided.",
            min_age=48, max_age=60, at_age=52, weight=16, priority=True,
            background="home", animation="confused", npc="derek",
            requires={"flags": ["derek_betrayed"], "missing_flags": ["derek_dead"], "npc_id": "derek", "npc_alive": True},
            choices=[
                choice("hear", "Hear him out.", {"flags_clear": ["derek_betrayed"], "npc_patch": {"id": "derek", "affection_delta": 14, "history": "You talked after the break."}}, [outcome("thin", "Trust comes back thin, but real.")]),
                choice("no", "Refuse the conversation.", {"npc_patch": {"id": "derek", "affection_delta": -8}}, [outcome("closed", "The door stays a door.")]),
            ],
        ),
    ]
    # Fix prison animation - I used a hack. Set properly below if needed.
    life = [
        ev(
            id="smoke_offer",
            category="health",
            text="Someone offers a cigarette behind the shops.",
            min_age=21, max_age=36, at_age=23, catch_at=30, catch_up=True, weight=18,
            background="apartment", animation="confused",
            choices=[
                choice(
                    "take",
                    "Take up smoking.",
                    {"flags_set": ["smoker"], "stats": {"stress": -4, "health": -2}, "memorable": "Started smoking."},
                    [outcome("light", "The first one tastes like a dare.", effects={"stats": {"stress": -2}})],
                    delayed=[
                        {"id": "smoke_45", "due_age": 45, "chance": 0.8, "text": "Old smoke sits in the lungs.", "effects": {"stats": {"health": -16}, "condition": "smoker's cough", "memorable": "Smoking hurt their health in midlife."}},
                        {"id": "smoke_62", "due_age": 62, "chance": 0.65, "text": "A doctor names the old damage.", "effects": {"stats": {"health": -20}, "flags_set": ["ill"], "condition": "lung disease", "memorable": "Illness followed years of smoking."}},
                    ],
                ),
                choice(
                    "drink",
                    "Share a drink instead.",
                    {"flags_set": ["heavy_drinker"], "stats": {"happiness": 2, "health": -1}},
                    [outcome("round", "The round is cheerful and a little too long.")],
                    delayed=[{"id": "drink_50", "due_age": 50, "chance": 0.55, "text": "The drinking leaves a mark.", "effects": {"stats": {"health": -12}, "condition": "liver strain"}}],
                ),
                choice("decline", "Decline and walk off.", {"flags_set": ["declined_smoke"], "stats": {"health": 2}}, [outcome("air", "The air outside is ordinary and good.")]),
            ],
        ),
        ev(
            id="exercise_choice",
            category="health",
            text="A friend bets you cannot keep an exercise habit.",
            min_age=24, max_age=48, at_age=25, catch_at=41, catch_up=True, weight=14,
            bias={"athleticism": 1.0},
            animation="walk",
            choices=[
                choice("train", "Train most days.", {"flags_set": ["fit"], "stats": {"fitness": 12, "health": 8, "stress": -4}, "memorable": "Built an exercise habit."}, [outcome("strong", "Your lungs start answering faster.")]),
                choice("sometimes", "Go sometimes.", {"stats": {"fitness": 4, "health": 2}}, [outcome("some", "Some weeks stick. Some do not.")]),
                choice("skip", "Skip it and sit down.", {"flags_set": ["sedentary"], "stats": {"fitness": -4, "stress": 2}}, [outcome("sofa", "The sofa wins on points.")]),
            ],
        ),
        ev(
            id="bridge_dare",
            category="adventure",
            text="Night on the river bridge. Someone dares a jump.",
            min_age=29, max_age=29, at_age=29, weight=40, priority=True,
            bias={"risk_tolerance": 1.2},
            background="apartment", animation="worried",
            choices=[
                choice(
                    "jump",
                    "Jump.",
                    {},
                    [
                        outcome("fine", "The water slaps, then you surface grinning.", weight=50, animation="jump", effects={"stats": {"happiness": 6, "health": -4}, "achievement": "Jumped the river bridge", "memorable": "Jumped the river bridge."}),
                        outcome("minor", "You clip the pier. A sprain, and a story.", weight=30, animation="injured", effects={"stats": {"health": -12}, "flags_set": ["injured"]}),
                        outcome("serious", "The current wins for a minute. Your ribs remember.", weight=15, animation="injured", effects={"stats": {"health": -28}, "flags_set": ["serious_injury"], "condition": "injured ribs"}),
                        outcome("death", "The river does not give you back.", weight=5, animation="dying", death="accident"),
                    ],
                    animation="jump",
                ),
                choice("refuse", "Refuse and step back.", {"stats": {"stress": -3, "happiness": -2}}, [outcome("dry", "You keep your feet dry and your pulse loud.")]),
                choice("persuade", "Talk everyone down.", {}, [
                    outcome("hero", "They laugh, then follow you off the bridge.", weight=7, effects={"stats": {"charisma": 6, "happiness": 5}, "achievement": "Talked friends off the bridge", "memorable": "Talked friends off the bridge."}),
                    outcome("mocked", "Someone calls you scared. The group splits.", weight=3, effects={"stats": {"happiness": -6, "stress": 6}}),
                ]),
                choice("record", "Record it instead of jumping.", {"stats": {"wealth": 12, "stress": 4}, "memorable": "Filmed the bridge dare instead of jumping."}, [outcome("clip", "The clip travels. So does a little regret.")]),
            ],
        ),
        ev(
            id="kathy_proposal",
            category="romance",
            storyline="kathy",
            text="Kathy is quiet in the good way. The moment is here.",
            min_age=32, max_age=32, at_age=32, weight=30, priority=True,
            background="home", animation="love", npc="kathy",
            requires={"flags": ["kathy_dating"], "missing_flags": ["kathy_married", "kathy_ended"], "npc_id": "kathy", "npc_alive": True},
            choices=[
                choice(
                    "propose",
                    "Ask Kathy to marry you.",
                    {},
                    [
                        outcome("yes", "She says yes. The room feels larger.", weight=3, animation="love", effects={
                            "flags_set": ["kathy_married"],
                            "relationship_status": "married",
                            "marriages": 1,
                            "memorable": "Married Kathy.",
                            "relationship_note": "Married Kathy.",
                            "achievement": "Married Kathy",
                            "npc_patch": {"id": "kathy", "name": "Kathy", "role": "spouse", "affection_delta": 15, "circumstances": "Married", "history": "Married Kathy."},
                        }),
                        outcome("no", "She loves you, and still says not yet.", weight=1, effects={"flags_set": ["kathy_rejected"], "relationship_status": "dating", "npc_patch": {"id": "kathy", "affection_delta": -12, "history": "Turned down a proposal."}}),
                    ],
                    animation="love",
                ),
                choice("wait", "Wait for another year.", {"stats": {"stress": 2}, "npc_patch": {"id": "kathy", "affection_delta": -4}}, [outcome("later", "The year stays ordinary.")]),
                choice("end", "End it gently.", {"flags_set": ["kathy_ended"], "relationship_status": "single", "npc_patch": {"id": "kathy", "role": "ex", "affection_delta": -10, "history": "You ended things."}}, [outcome("soft", "It ends without a scene. It still hurts.")]),
            ],
        ),
        ev(
            id="married_life",
            category="romance",
            storyline="kathy",
            text="Married life with Kathy has a rhythm and a squeaky door.",
            min_age=34, max_age=42, at_age=35, weight=10,
            background="home", animation="love", npc="kathy",
            requires={"flags": ["kathy_married"], "relationship": ["married"], "npc_id": "kathy", "npc_alive": True},
            choices=[
                choice("trip", "Plan a small trip together.", {"stats": {"happiness": 6, "wealth": -8}, "npc_patch": {"id": "kathy", "affection_delta": 6, "history": "Took a trip together."}}, [outcome("train", "The train is late. You do not mind.")]),
                choice("nest", "Nest in and fix the door.", {"stats": {"happiness": 3}, "housing": "house"}, [outcome("home", "The squeak goes. The quiet stays.")]),
            ],
        ),
        ev(
            id="child_choice",
            category="family",
            text="The question of a child sits between you at breakfast.",
            min_age=30, max_age=42, at_age=33, weight=12,
            background="home", animation="confused",
            requires={"relationship": ["married"]},
            choices=[
                choice("try", "Try for a child.", {}, [
                    outcome("baby", "A baby arrives, loud and astonishing.", weight=3, animation="hold_baby", effects={"add_child": True, "stats": {"happiness": 10, "stress": 6}}),
                    outcome("notyet", "Not this year. You keep the conversation.", weight=1, effects={"stats": {"stress": 2}}),
                ], animation="hold_baby"),
                choice("not_now", "Decide not now.", {"flags_set": ["delayed_children"], "stats": {"stress": -2}}, [outcome("space", "The flat stays quiet a while longer.")]),
            ],
        ),
        ev(
            id="parenting_night",
            category="family",
            text="{child_name} is awake and asking for water.",
            min_age=28, max_age=55, at_age=36, weight=11,
            background="home", animation="hold_baby",
            placeholders=["child_name"],
            requires={"has_children": True},
            choices=[
                choice("sit", "Sit with them until sleep.", {"stats": {"happiness": 4, "stress": 3}}, [outcome("soft", "The water is an excuse. The company is not.")]),
                choice("trade", "Ask your partner to take a turn.", {"stats": {"stress": -2}}, [outcome("turn", "You sleep. Someone else learns the song.")]),
            ],
        ),
        ev(
            id="buy_home",
            category="finance",
            text="A home of your own is suddenly a real choice.",
            min_age=34, max_age=55, at_age=41, weight=9,
            background="home", animation="confused",
            choices=[
                choice("house", "Buy a modest house.", {"housing": "house", "stats": {"wealth": -70, "happiness": 6}, "memorable": "Bought a house."}, [outcome("key", "The key is ordinary and huge.")]),
                choice("rent", "Keep renting.", {"flags_set": ["kept_renting"], "stats": {"stress": -2}}, [outcome("lease", "The lease renews. So do you.")]),
                choice("mansion", "Stretch for a mansion.", {"housing": "mansion", "stats": {"wealth": -180, "stress": 8, "happiness": 4}, "memorable": "Moved into a mansion."}, [outcome("echo", "The rooms echo. The bills do too.")]),
            ],
        ),
        ev(
            id="windfall",
            category="luck",
            text="Unexpected money shows up with your name on it.",
            min_age=30, max_age=60, at_age=37, weight=5, bias={"luck": 0.6},
            animation="celebrate",
            choices=[
                choice("save", "Save almost all of it.", {"stats": {"wealth": 50}}, [outcome("quiet", "The account looks healthier than you feel.", animation="earn_money")]),
                choice("spend", "Spend it on a better week.", {"stats": {"wealth": 10, "happiness": 8}}, [outcome("week", "The week is bright and then gone.")]),
            ],
        ),
        ev(
            id="debt_squeeze",
            category="finance",
            text="A debt letter arrives, printed in stern ink.",
            min_age=26, max_age=55, at_age=29, catch_at=34, catch_up=True, weight=12,
            background="apartment", animation="worried",
            requires={"flags": ["has_debt"]},
            choices=[
                choice("pay", "Pay a painful chunk now.", {"debt": -12, "stats": {"wealth": -12, "stress": -3}}, [outcome("lighter", "The letter gets shorter.")]),
                choice("ignore", "Ignore it this month.", {"debt": 4, "stats": {"stress": 6}}, [outcome("later", "Later arrives with interest.")]),
            ],
        ),
        ev(
            id="parent_health",
            category="family",
            text="A parent is ill and pretending otherwise.",
            min_age=38, max_age=60, at_age=45, weight=8,
            background="home", animation="worried",
            choices=[
                choice("help", "Move closer and help.", {"stats": {"happiness": 2, "stress": 5, "wealth": -8}, "memorable": "Cared for a parent."}, [outcome("days", "The days are long and worth it.")]),
                choice("money", "Send money instead.", {"stats": {"wealth": -15}}, [outcome("transfer", "The transfer goes. The worry stays.")]),
                choice("away", "Stay away.", {"stats": {"stress": 4, "happiness": -4}}, [outcome("distance", "Distance does not shrink the news.")]),
            ],
        ),
        ev(
            id="lottery_ticket",
            category="luck",
            text="A lottery ticket could be dinner, or something louder.",
            min_age=28, max_age=70, at_age=40, weight=3,
            animation="confused",
            choices=[
                choice("buy", "Buy the ticket.", {}, [
                    outcome("win", "The numbers hit. Modestly, gloriously.", weight=1, animation="celebrate", effects={"stats": {"wealth": 220}, "achievement": "Won a modest lottery", "memorable": "Won a modest lottery."}),
                    outcome("lose", "The numbers miss. Dinner is plain.", weight=12, effects={"stats": {"wealth": -2}}),
                ]),
                choice("skip", "Keep the coins.", {"stats": {"wealth": 1}}, [outcome("pocket", "Your pocket stays honest.")]),
            ],
        ),
        ev(
            id="shady_offer",
            category="crime",
            text="Someone offers fast money and no receipt.",
            min_age=30, max_age=50, at_age=34, weight=4, bias={"risk_tolerance": 1.0},
            background="apartment", animation="worried",
            excludes={"flags": ["in_prison"]},
            choices=[
                choice("walk", "Walk away.", {"stats": {"stress": -2}}, [outcome("clean", "You leave with empty hands and a clean name.")]),
                choice("take", "Take the job.", {}, [
                    outcome("rich", "The cash arrives. So does a bad sleep.", weight=1, effects={"stats": {"wealth": 90, "stress": 10}, "flags_set": ["shady_past"]}),
                    outcome("prison", "It was a trap. Prison sticks.", weight=1, animation="cry", effects={"flags_set": ["in_prison"], "employment": "none", "career": "", "memorable": "Went to prison."}),
                ]),
            ],
        ),
        ev(
            id="business_lawsuit",
            category="finance",
            text="A customer is suing the business you own.",
            min_age=32, max_age=60, at_age=46, weight=10,
            background="office", animation="angry",
            requires={"flags": ["owns_business"]},
            choices=[
                choice("settle", "Settle and move on.", {"stats": {"wealth": -36, "stress": -2}}, [outcome("papers", "The papers go away. The money does too.", animation="lose_money")]),
                choice("fight", "Fight it in court.", {}, [
                    outcome("win", "The court sides with you.", weight=1, effects={"stats": {"wealth": 12, "stress": 4}}),
                    outcome("lose", "You lose, and the bill is rude.", weight=1, animation="lose_money", effects={"stats": {"wealth": -48, "stress": 8}}),
                ]),
            ],
        ),
        ev(
            id="divorce_papers",
            category="romance",
            storyline="kathy",
            text="Divorce papers sit on the table, waiting for a pen.",
            min_age=36, max_age=60, at_age=42, weight=12,
            background="home", animation="cry", npc="kathy",
            requires={"relationship": ["married"], "flags": ["kathy_married"]},
            choices=[
                choice("sign", "Sign them.", {"relationship_status": "separated", "flags_set": ["divorced", "kathy_separated"], "flags_clear": ["kathy_married"], "memorable": "Divorced Kathy.", "npc_patch": {"id": "kathy", "name": "Kathy", "role": "ex", "affection_delta": -20, "circumstances": "Separated", "history": "Divorced."}}, [outcome("quiet", "The pen is louder than the room.")]),
                choice("wait", "Ask to wait and talk.", {"stats": {"stress": 4}, "npc_patch": {"id": "kathy", "affection_delta": 2}}, [outcome("talk", "You talk until the paper looks less final.")]),
            ],
        ),
        ev(
            id="promotion",
            category="career",
            text="A promotion is offered, with longer days attached.",
            min_age=32, max_age=50, at_age=38, weight=9,
            background="office", animation="confused",
            requires={"flags": ["employed"]},
            excludes={"flags": ["in_prison"]},
            choices=[
                choice("take", "Take the promotion.", {"income_delta": 6, "stats": {"stress": 6, "wealth": 10}, "achievement": "Promoted at work", "memorable": "Took a promotion."}, [outcome("title", "The title is heavier than the chair.")]),
                choice("decline", "Decline and keep your evenings.", {"stats": {"happiness": 4, "stress": -3}}, [outcome("evening", "Evenings stay yours.")]),
            ],
        ),
        ev(
            id="layoff",
            category="career",
            text="The company calls it restructuring. Your badge stops.",
            min_age=34, max_age=55, at_age=39, weight=8,
            background="office", animation="worried",
            requires={"flags": ["employed"]},
            choices=[
                choice("hunt", "Hunt for work at once.", {"employment": "none", "income": 0, "stats": {"stress": 8}, "flags_set": ["job_hunting"]}, [outcome("ads", "The ads are many. The replies are few.")]),
                choice("rest", "Rest before you search.", {"employment": "none", "income": 0, "stats": {"happiness": -3, "stress": -2}}, [outcome("pause", "The pause helps, then the bills speak.")]),
            ],
        ),
        ev(
            id="qualified_offer",
            category="career",
            storyline="career",
            text="A senior post wants the qualification you earned.",
            min_age=40, max_age=58, at_age=46, catch_at=46, catch_up=True, weight=16,
            bias={"ambition": 1.0},
            background="hospital", animation="confused",
            requires={"flags": ["degree", "prestigious_university"]},
            excludes={"flags": ["in_prison"]},
            choices=[
                choice("medicine", "Take the medical path.", {"career": "Doctor", "employment": "employed", "income": 28, "qualification": "Medical qualification", "achievement": "Became a doctor", "memorable": "Became a doctor."}, [outcome("coat", "The coat fits. The nights are long.", animation="celebrate")]),
                choice("engineering", "Take the engineering path.", {"career": "Engineer", "employment": "employed", "income": 24, "qualification": "Engineering qualification", "achievement": "Became an engineer", "memorable": "Became an engineer."}, [outcome("plan", "The plans are clean. The pay is too.")]),
                choice("no", "Stay where you are.", {"stats": {"stress": -2}}, [outcome("same", "The old desk remains loyal.")]),
            ],
        ),
        ev(
            id="checkup",
            category="health",
            text="A checkup finds a number your doctor circles twice.",
            min_age=44, max_age=70, at_age=47, weight=8,
            background="hospital", animation="worried",
            choices=[
                choice("follow", "Follow the advice.", {"stats": {"health": 8, "stress": -2}}, [outcome("better", "The next number is kinder.")]),
                choice("skip", "Skip the follow-up.", {}, [
                    outcome("fine", "You feel fine, which is not data.", weight=2),
                    outcome("ill", "The skipped visit comes back louder.", weight=1, effects={"flags_set": ["ill"], "stats": {"health": -14}, "condition": "untreated illness"}),
                ]),
            ],
        ),
        ev(
            id="risk_trip",
            category="adventure",
            text="A last-minute trip promises stories and bad weather.",
            min_age=26, max_age=55, at_age=43, weight=6, bias={"risk_tolerance": 0.8},
            animation="walk",
            choices=[
                choice("go", "Go anyway.", {}, [
                    outcome("story", "You come home sunburned and glad.", weight=8, effects={"stats": {"happiness": 7, "wealth": -10}}),
                    outcome("hurt", "A fall leaves a limp for a season.", weight=3, animation="injured", effects={"stats": {"health": -10}, "flags_set": ["injured"]}),
                    outcome("death", "The weather turns, and does not turn back.", weight=1, animation="dying", death="accident"),
                ]),
                choice("stay", "Stay home.", {"stats": {"stress": -2}}, [outcome("window", "You watch the rain from a safe chair.")]),
            ],
        ),
        ev(
            id="grey_morning",
            category="ageing",
            text="The mirror has started keeping secrets in silver.",
            min_age=48, max_age=60, at_age=51, weight=7,
            background="home", animation="ageing",
            choices=[
                choice("dye", "Dye it and carry on.", {"stats": {"happiness": 2}}, [outcome("bottle", "The bottle helps the mirror, briefly.")]),
                choice("grey", "Let the silver stay.", {"stats": {"confidence": 0, "happiness": 3}}, [outcome("own", "You decide it looks like evidence of living.")]),
            ],
        ),
        ev(
            id="health_vs_job",
            category="health",
            storyline="career",
            text="Your body asks for rest your job will not give.",
            min_age=50, max_age=64, at_age=54, weight=12,
            background="hospital", animation="sick",
            requires={"flags": ["employed"], "any_flags": ["ill", "serious_injury", "smoker"]},
            choices=[
                choice("rest", "Step back and heal.", {"employment": "none", "income": 0, "stats": {"health": 10, "stress": -6}, "flags_set": ["career_break"]}, [outcome("slow", "The days get slower and kinder.")]),
                choice("push", "Push through the hours.", {"stats": {"health": -12, "wealth": 12, "stress": 8}}, [outcome("grind", "The paycheck arrives. So does the cough.")]),
                choice("quit", "Quit while you still can.", {"employment": "none", "income": 0, "stats": {"happiness": 2, "stress": -4}}, [outcome("door", "You leave the badge on the desk.")]),
            ],
        ),
        ev(
            id="loss_in_family",
            category="tragedy",
            text="The family gathers for a goodbye nobody wanted.",
            min_age=50, max_age=75, at_age=58, weight=7,
            background="home", animation="cry",
            choices=[
                choice("there", "Be there for all of it.", {"stats": {"happiness": -6, "stress": 4}, "memorable": "Said goodbye to a parent."}, [outcome("hand", "You hold a hand until it is time.")]),
                choice("send", "Send love and stay away.", {"stats": {"happiness": -4, "wealth": -6}}, [outcome("letter", "The letter is not the same as being there.")]),
            ],
        ),
        ev(
            id="friend_hike",
            category="social",
            text="{friend_name} wants the long trail before dark.",
            min_age=22, max_age=60, at_age=27, weight=7, bias={"sociability": 1.0},
            animation="walk",
            placeholders=["friend_name"],
            choices=[
                choice("go", "Take the long trail.", {"stats": {"fitness": 4, "happiness": 5}}, [outcome("view", "The view is worth the mud.")]),
                choice("home", "Stay in.", {"stats": {"stress": -2}}, [outcome("sofa", "The sofa has no hills. You like that.")]),
            ],
        ),
        ev(
            id="retirement_gate",
            category="ageing",
            text="The calendar says you could stop working.",
            min_age=66, max_age=66, at_age=66, weight=20, priority=True,
            background="retirement", animation="sit",
            choices=[
                choice("retire", "Retire.", {"flags_set": ["retired"], "employment": "none", "income": 4, "memorable": "Retired."}, [outcome("garden", "Mornings arrive without a badge.", animation="celebrate")]),
                choice("stay", "Keep working a little longer.", {"stats": {"stress": 4, "wealth": 8}}, [outcome("desk", "The desk still wants you. You still go.")]),
            ],
        ),
        ev(
            id="slow_stairs",
            category="ageing",
            text="Stairs take longer than they used to.",
            min_age=72, max_age=72, at_age=72, weight=16, priority=True,
            background="retirement", animation="ageing",
            choices=[
                choice("slower", "Move slower and keep going.", {"stats": {"health": 3, "stress": -2}}, [outcome("pace", "Your pace becomes a kind of wisdom.")]),
                choice("ignore", "Ignore the ache.", {"stats": {"health": -8, "stress": 3}}, [outcome("ache", "The ache keeps your schedule for you.")]),
            ],
        ),
    ]
    fallbacks = []
    bands = [
        (0, 9, "childhood", "home", "A small ordinary day asks nothing heroic."),
        (10, 19, "education", "school", "School, weather, and a joke you repeat."),
        (20, 29, "social", "apartment", "The week is ordinary and still yours."),
        (30, 39, "career", "office", "Work, a meal, and an early night."),
        (40, 49, "family", "home", "A regular day with one small kindness."),
        (50, 59, "health", "home", "You notice the afternoon light and rest."),
        (60, 69, "ageing", "retirement", "The day is quiet enough to hear birds."),
        (70, 79, "ageing", "retirement", "Tea, a chair, and a story retold."),
        (80, 89, "ageing", "retirement", "The morning is slow and surprisingly sweet."),
        (90, 109, "ageing", "retirement", "Another day arrives. You greet it."),
    ]
    for lo, hi, category, background, text in bands:
        fallbacks.append(
            ev(
                id="fallback_%02d" % lo,
                category=category,
                text=text,
                min_age=lo,
                max_age=hi,
                at_age=lo,
                weight=1,
                once=False,
                fallback=True,
                background=background,
                animation="idle",
                choices=[
                    choice("engage", "Lean into the day.", {"stats": {"happiness": 2}}, [outcome("good", "It becomes a good small memory.")]),
                    choice("rest", "Rest and let it pass.", {"stats": {"health": 1, "stress": -1}}, [outcome("calm", "Calm is enough today.")]),
                ],
            )
        )
    return {
        "childhood.json": childhood,
        "education.json": education,
        "derek.json": derek,
        "life.json": life,
        "fallbacks.json": fallbacks,
    }


def main() -> None:
    groups = pack()
    ids = []
    count = 0
    problems = []
    for name, rows in groups.items():
        for row in rows:
            count += 1
            if row["id"] in ids:
                problems.append("duplicate " + row["id"])
            ids.append(row["id"])
            if words(row["text"]) > 30:
                problems.append("%s text %d" % (row["id"], words(row["text"])))
            choices = row["choices"]
            if not 2 <= len(choices) <= 4:
                problems.append("%s choices %d" % (row["id"], len(choices)))
            for item in choices:
                if words(item["label"]) > 12:
                    problems.append("%s label %s" % (row["id"], item["label"]))
                for result in item["outcomes"]:
                    if words(result["text"]) > 30:
                        problems.append("%s outcome %s" % (row["id"], result["text"]))
        OUT.mkdir(parents=True, exist_ok=True)
        (OUT / name).write_text(json.dumps(rows, indent=2), encoding="utf-8")
        print(name, len(rows))
    names = {
        "female": ["Ada", "Mae", "Ruth", "Iris", "Nora", "Lila", "June", "Esme", "Clara", "Freya", "Hana", "Priya", "Leila", "Mina", "Sable", "Willa", "Greta", "Nina", "Opal", "Thea"],
        "male": ["Arthur", "Leo", "Owen", "Felix", "Jonah", "Miles", "Hugo", "Samir", "Eli", "Oscar", "Theo", "Malik", "Ruben", "Idris", "Casper", "Nico", "Harun", "Paolo", "Seth", "Victor"],
        "neutral": ["Alex", "River", "Quinn", "Rowan", "Shay", "Eden", "Ari", "Noel", "Remy", "Sage", "Jules", "Kerry", "Ash", "Blair", "Drew", "Emery", "Frankie", "Harper", "Indigo", "Kit"],
        "surnames": ["Wells", "Okoye", "Berg", "Santos", "Novak", "Adler", "Cho", "Rahman", "Ibrahim", "Costa", "Moreau", "Singh", "Almeida", "Keller", "Duval", "Haddad", "Petrov", "Silva", "Nakamura", "Brooks"],
    }
    (ROOT / "data" / "names.json").write_text(json.dumps(names, indent=2), encoding="utf-8")
    print("events", count)
    if problems:
        print("PROBLEMS")
        for problem in problems:
            print(problem)
        raise SystemExit(1)


if __name__ == "__main__":
    main()
