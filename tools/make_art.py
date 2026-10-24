"""Placeholder pixel sheets. Key colours are replaced in game for hair, skin, and eyes."""

import json
import struct
import zlib
from pathlib import Path

ROOT = Path(r"S:\PROJECTS\A life well lived")
SKIN = (255, 0, 170, 255)
HAIR = (255, 170, 0, 255)
EYE = (0, 229, 255, 255)
OUT = (32, 26, 48, 255)
WHITE = (255, 248, 240, 255)
BLUSH = (255, 146, 162, 255)
TEAR = (90, 170, 255, 255)
GOLD = (242, 193, 78, 255)
RED = (220, 70, 70, 255)

STAGES = {
    "baby": {"y": 16, "head": 14, "body": (8, 8), "leg": 4, "cloth": (120, 220, 190, 255), "pants": (120, 220, 190, 255), "cane": False},
    "child": {"y": 8, "head": 12, "body": (10, 10), "leg": 8, "cloth": (255, 196, 70, 255), "pants": (70, 130, 230, 255), "cane": False},
    "teen": {"y": 4, "head": 11, "body": (10, 12), "leg": 10, "cloth": (46, 196, 182, 255), "pants": (52, 58, 99, 255), "cane": False},
    "young_adult": {"y": 1, "head": 11, "body": (12, 13), "leg": 12, "cloth": (255, 107, 90, 255), "pants": (44, 52, 96, 255), "cane": False},
    "adult": {"y": 1, "head": 11, "body": (12, 13), "leg": 12, "cloth": (70, 110, 220, 255), "pants": (40, 44, 70, 255), "cane": False},
    "middle_aged": {"y": 2, "head": 11, "body": (13, 13), "leg": 11, "cloth": (150, 70, 120, 255), "pants": (54, 46, 72, 255), "cane": False},
    "elderly": {"y": 5, "head": 11, "body": (12, 12), "leg": 9, "cloth": (160, 120, 200, 255), "pants": (62, 56, 84, 255), "cane": True},
    "very_elderly": {"y": 8, "head": 11, "body": (12, 11), "leg": 8, "cloth": (90, 150, 110, 255), "pants": (50, 54, 62, 255), "cane": True},
}

ANIMS = [
    ("idle", 4, 4, True, 1.2),
    ("walk", 4, 8, True, 1.4),
    ("sleep", 2, 2, True, 1.6),
    ("sit", 2, 2, True, 1.2),
    ("jump", 2, 8, False, 1.2),
    ("laugh", 2, 6, True, 1.5),
    ("cry", 2, 3, True, 1.6),
    ("celebrate", 2, 6, True, 1.8),
    ("confused", 2, 3, True, 1.4),
    ("worried", 2, 3, True, 1.5),
    ("angry", 2, 4, True, 1.4),
    ("love", 2, 4, True, 1.6),
    ("embarrassed", 2, 3, True, 1.4),
    ("sick", 2, 2, True, 1.8),
    ("injured", 2, 2, True, 1.6),
    ("hug", 2, 3, True, 1.5),
    ("hold_baby", 2, 3, True, 1.8),
    ("earn_money", 2, 5, False, 1.5),
    ("lose_money", 2, 5, False, 1.5),
    ("ageing", 2, 3, False, 2.0),
    ("dying", 3, 2, False, 2.4),
]


def write_png(path: Path, width: int, height: int, rows) -> None:
    raw = b"".join(b"\x00" + bytes(row) for row in rows)
    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(png)


def blank(width, height):
    return [[(0, 0, 0, 0) for _ in range(width)] for _ in range(height)]


def pix(frame, x, y, color):
    if 0 <= x < len(frame[0]) and 0 <= y < len(frame):
        frame[y][x] = color


def rect(frame, x, y, w, h, color):
    for yy in range(y, y + h):
        for xx in range(x, x + w):
            pix(frame, xx, yy, color)


def blob(frame, x, y, w, h, fill):
    rect(frame, x, y, w, h, OUT)
    if w > 2 and h > 2:
        rect(frame, x + 1, y + 1, w - 2, h - 2, fill)


def flatten(frame):
    return [bytes(channel for pixel in row for channel in pixel) for row in frame]


def pose_for(name, frame_index):
    pose = {"dy": 0, "leg": 0, "arm": 0, "expr": "neutral", "lie": False, "prop": None}
    if name == "idle":
        pose["dy"] = [0, -1, 0, -1][frame_index % 4]
    elif name == "walk":
        pose["leg"] = [2, 0, -2, 0][frame_index % 4]
        pose["arm"] = [-2, 0, 2, 0][frame_index % 4]
        pose["dy"] = [0, -1, 0, -1][frame_index % 4]
    elif name == "sleep":
        pose["lie"] = True
        pose["expr"] = "closed"
        pose["prop"] = "zzz" if frame_index % 2 == 0 else None
    elif name == "sit":
        pose["dy"] = 4
        pose["leg"] = 0
        pose["expr"] = "neutral"
    elif name == "jump":
        pose["dy"] = -6 if frame_index == 1 else -2
        pose["arm"] = -3
    elif name == "laugh":
        pose["expr"] = "laugh"
        pose["dy"] = [0, -1][frame_index % 2]
    elif name == "cry":
        pose["expr"] = "cry"
    elif name == "celebrate":
        pose["arm"] = -4
        pose["expr"] = "laugh"
        pose["dy"] = [0, -2][frame_index % 2]
        pose["prop"] = "star"
    elif name == "confused":
        pose["expr"] = "confused"
        pose["prop"] = "ask"
    elif name == "worried":
        pose["expr"] = "worried"
        pose["prop"] = "sweat"
    elif name == "angry":
        pose["expr"] = "angry"
        pose["arm"] = 3
    elif name == "love":
        pose["expr"] = "love"
        pose["prop"] = "heart"
    elif name == "embarrassed":
        pose["expr"] = "blush"
    elif name == "sick":
        pose["expr"] = "sick"
        pose["prop"] = "thermo"
        pose["dy"] = 1
    elif name == "injured":
        pose["expr"] = "hurt"
        pose["prop"] = "bandage"
    elif name == "hug":
        pose["arm"] = 4
        pose["expr"] = "love"
    elif name == "hold_baby":
        pose["arm"] = 2
        pose["prop"] = "baby"
    elif name == "earn_money":
        pose["prop"] = "coin"
        pose["expr"] = "laugh"
        pose["dy"] = [0, -1][frame_index % 2]
    elif name == "lose_money":
        pose["prop"] = "drop"
        pose["expr"] = "cry"
    elif name == "ageing":
        pose["prop"] = "spark"
        pose["dy"] = frame_index
    elif name == "dying":
        pose["lie"] = True
        pose["expr"] = "closed"
        pose["dy"] = frame_index
    return pose


def draw_person(stage, pose):
    spec = STAGES[stage]
    frame = blank(32, 48)
    if pose["lie"]:
        draw_lying(frame, spec, pose)
        return frame
    dy = spec["y"] + pose["dy"]
    cx = 15
    head = spec["head"]
    top = 4 + dy
    blob(frame, cx - head // 2, top, head, 5, HAIR)
    blob(frame, cx - head // 2 + 1, top + 3, head - 2, head - 3, SKIN)
    eye_y = top + 7
    eye_x = cx - 3
    if pose["expr"] == "closed":
        rect(frame, eye_x, eye_y, 2, 1, OUT)
        rect(frame, eye_x + 4, eye_y, 2, 1, OUT)
    else:
        rect(frame, eye_x, eye_y, 2, 2, WHITE)
        rect(frame, eye_x + 4, eye_y, 2, 2, WHITE)
        pix(frame, eye_x, eye_y, EYE)
        pix(frame, eye_x + 4, eye_y, EYE)
    if pose["expr"] == "laugh":
        rect(frame, cx - 2, eye_y + 4, 4, 2, RED)
    elif pose["expr"] == "cry":
        pix(frame, eye_x, eye_y + 2, TEAR)
        pix(frame, eye_x + 5, eye_y + 3, TEAR)
    elif pose["expr"] == "angry":
        pix(frame, eye_x - 1, eye_y - 1, RED)
        pix(frame, eye_x + 5, eye_y - 1, RED)
    elif pose["expr"] == "blush":
        pix(frame, eye_x - 2, eye_y + 2, BLUSH)
        pix(frame, eye_x + 6, eye_y + 2, BLUSH)
    elif pose["expr"] == "sick":
        pix(frame, cx - 1, eye_y + 4, ColorGreen())
    bw, bh = spec["body"]
    body_y = top + head - 1
    blob(frame, cx - bw // 2, body_y, bw, bh, spec["cloth"])
    leg_h = spec["leg"]
    leg_y = body_y + bh - 1
    shift = pose["leg"]
    blob(frame, cx - bw // 2, leg_y, 4, leg_h, spec["pants"])
    blob(frame, cx + bw // 2 - 4, leg_y, 4, max(3, leg_h - abs(shift)), spec["pants"])
    arm = pose["arm"]
    blob(frame, cx - bw // 2 - 3, body_y + 2 + max(0, arm), 3, 7, spec["cloth"])
    blob(frame, cx + bw // 2, body_y + 2 - min(0, arm), 3, 7, spec["cloth"])
    if spec["cane"]:
        rect(frame, cx + bw // 2 + 4, body_y + 4, 1, leg_h + 6, OUT)
    draw_prop(frame, pose.get("prop"), cx, top)
    return frame


def ColorGreen():
    return (120, 190, 90, 255)


def draw_lying(frame, spec, pose):
    blob(frame, 4, 28, 8, 8, HAIR)
    blob(frame, 5, 30, 6, 6, SKIN)
    rect(frame, 7, 32, 2, 1, OUT)
    blob(frame, 12, 30, 14, 6, spec["cloth"])
    blob(frame, 24, 31, 6, 4, spec["pants"])
    if pose.get("prop") == "zzz":
        pix(frame, 14, 24, EYE)
        pix(frame, 16, 22, EYE)
    if pose["dy"]:
        rect(frame, 6, 38, 18, 1, OUT)


def draw_prop(frame, prop, cx, top):
    if prop == "heart":
        pix(frame, cx + 8, top + 2, RED)
        pix(frame, cx + 9, top + 1, RED)
        pix(frame, cx + 10, top + 2, RED)
    elif prop == "ask":
        pix(frame, cx + 8, top, GOLD)
        pix(frame, cx + 9, top, GOLD)
        pix(frame, cx + 8, top + 3, GOLD)
    elif prop == "sweat":
        pix(frame, cx + 8, top + 4, TEAR)
    elif prop == "star":
        pix(frame, cx - 8, top, GOLD)
    elif prop == "thermo":
        rect(frame, cx + 8, top + 6, 1, 5, WHITE)
        pix(frame, cx + 8, top + 10, RED)
    elif prop == "bandage":
        rect(frame, cx - 2, top + 6, 4, 2, WHITE)
        pix(frame, cx, top + 6, RED)
    elif prop == "baby":
        blob(frame, cx + 6, top + 12, 6, 6, SKIN)
        rect(frame, cx + 7, top + 11, 4, 2, HAIR)
    elif prop == "coin":
        rect(frame, cx + 8, top + 8, 3, 3, GOLD)
    elif prop == "drop":
        rect(frame, cx + 8, top + 16, 3, 3, GOLD)
    elif prop == "spark":
        pix(frame, cx - 8, top + 2, GOLD)
        pix(frame, cx + 9, top + 1, WHITE)


def sheet_for(stage):
    frames = []
    for name, count, _fps, _loop, _hold in ANIMS:
        for index in range(count):
            frames.append(draw_person(stage, pose_for(name, index)))
    columns = 8
    width = columns * 32
    rows = (len(frames) + columns - 1) // columns
    height = rows * 48
    image = blank(width, height)
    for index, frame in enumerate(frames):
        ox = (index % columns) * 32
        oy = (index // columns) * 48
        for y in range(48):
            for x in range(32):
                image[oy + y][ox + x] = frame[y][x]
    return image, width, height


def background(kind):
    image = blank(180, 120)
    palettes = {
        "home": ((242, 211, 162, 255), (141, 90, 60, 255), (120, 170, 210, 255)),
        "apartment": ((201, 214, 234, 255), (90, 98, 120, 255), (130, 190, 140, 255)),
        "mansion": ((247, 231, 176, 255), (120, 84, 48, 255), (242, 193, 78, 255)),
        "school": ((244, 225, 181, 255), (92, 140, 90, 255), (70, 90, 140, 255)),
        "university": ((217, 199, 162, 255), (90, 70, 50, 255), (80, 110, 160, 255)),
        "office": ((215, 227, 234, 255), (70, 90, 110, 255), (80, 200, 170, 255)),
        "hospital": ((231, 242, 242, 255), (180, 210, 210, 255), (220, 80, 80, 255)),
        "retirement": ((142, 202, 230, 255), (124, 179, 66, 255), (230, 120, 150, 255)),
    }
    wall, floor, accent = palettes[kind]
    rect(image, 0, 0, 180, 78, wall)
    rect(image, 0, 78, 180, 42, floor)
    rect(image, 18, 16, 36, 28, accent)
    rect(image, 22, 20, 28, 20, (230, 245, 255, 255))
    if kind == "mansion":
        rect(image, 8, 10, 8, 68, (230, 210, 160, 255))
        rect(image, 164, 10, 8, 68, (230, 210, 160, 255))
        rect(image, 80, 8, 20, 10, GOLD)
    elif kind == "hospital":
        rect(image, 78, 86, 40, 16, WHITE)
        rect(image, 96, 36, 8, 20, RED)
        rect(image, 90, 42, 20, 8, RED)
    elif kind == "retirement":
        rect(image, 0, 70, 180, 50, floor)
        rect(image, 40, 80, 36, 8, (120, 80, 50, 255))
        rect(image, 120, 88, 8, 8, accent)
        rect(image, 132, 84, 8, 8, GOLD)
    elif kind in ("office", "school", "university"):
        rect(image, 70, 84, 50, 16, (90, 70, 50, 255))
        rect(image, 86, 76, 18, 10, accent)
    else:
        rect(image, 96, 86, 40, 16, (180, 90, 70, 255))
        rect(image, 24, 90, 28, 10, (200, 90, 80, 255))
    return image


def portrait():
    image = blank(32, 32)
    blob(image, 8, 2, 16, 8, HAIR)
    blob(image, 9, 8, 14, 14, SKIN)
    rect(image, 12, 13, 3, 3, WHITE)
    rect(image, 18, 13, 3, 3, WHITE)
    pix(image, 13, 14, EYE)
    pix(image, 19, 14, EYE)
    rect(image, 14, 19, 4, 2, RED)
    return image


def icon():
    image = blank(64, 64)
    rect(image, 0, 0, 64, 64, (28, 26, 51, 255))
    blob(image, 20, 8, 24, 12, HAIR)
    blob(image, 22, 16, 20, 18, SKIN)
    rect(image, 26, 22, 4, 4, WHITE)
    rect(image, 34, 22, 4, 4, WHITE)
    pix(image, 27, 23, EYE)
    pix(image, 35, 23, EYE)
    blob(image, 24, 34, 16, 16, (255, 107, 90, 255))
    return image


def main() -> None:
    animations = {}
    start = 0
    for name, count, fps, loop, hold in ANIMS:
        animations[name] = {"start": start, "frames": count, "fps": fps, "loop": loop, "hold": hold}
        start += count
    stages = {}
    char_dir = ROOT / "assets" / "characters"
    for stage in STAGES:
        image, width, height = sheet_for(stage)
        path = char_dir / f"{stage}.png"
        write_png(path, width, height, flatten(image))
        stages[stage] = f"res://assets/characters/{stage}.png"
        print(stage, width, height)
    data = {"frame_size": [32, 48], "columns": 8, "palette": True, "stages": stages, "animations": animations}
    (ROOT / "data" / "animations.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    bg_dir = ROOT / "assets" / "backgrounds"
    for name in ["home", "apartment", "mansion", "school", "university", "office", "hospital", "retirement"]:
        image = background(name)
        write_png(bg_dir / f"{name}.png", 180, 120, flatten(image))
    face = portrait()
    write_png(ROOT / "assets" / "npcs" / "portrait.png", 32, 32, flatten(face))
    mark = icon()
    write_png(ROOT / "icon.png", 64, 64, flatten(mark))
    print("frames", start)


if __name__ == "__main__":
    main()
