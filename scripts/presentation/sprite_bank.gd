class_name SpriteBank
extends RefCounted

## Animation ids map to frames. Placeholder sheets use key colours for hair, skin, and eyes.

static var _data: Dictionary = {}
static var _ready: bool = false
static var _baked: Dictionary = {}
static var _backgrounds: Dictionary = {}

const SKIN_KEY := Color(1.0, 0.0, 170.0 / 255.0)
const HAIR_KEY := Color(1.0, 170.0 / 255.0, 0.0)
const EYE_KEY := Color(0.0, 229.0 / 255.0, 1.0)

const SKINS := {
	"fair": Color("f6d3b4"),
	"olive": Color("d2a06a"),
	"tan": Color("c68642"),
	"brown": Color("8d5524"),
	"deep": Color("5c3317"),
}
const HAIR := {
	"black": Color("2a2424"),
	"brown": Color("6b3e26"),
	"blonde": Color("e6c36a"),
	"red": Color("c2412d"),
	"auburn": Color("a8572a"),
}
const EYES := {
	"brown": Color("6b4423"),
	"blue": Color("3a7bd5"),
	"green": Color("2f8f4e"),
	"hazel": Color("8a7a3a"),
	"amber": Color("c4842a"),
}


static func ensure() -> void:
	if _ready:
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/animations.json"))
	if typeof(parsed) == TYPE_DICTIONARY:
		_data = parsed
	_ready = true


static func stage_key(years: int) -> String:
	return LifeSim.stage_for_age(years)


static func sheet_path(stage: String) -> String:
	ensure()
	var stages: Dictionary = _data.get("stages", {})
	if stages.has(stage):
		return str(stages[stage])
	return "res://assets/characters/%s.png" % stage


static func anim(id: String) -> Dictionary:
	ensure()
	var all: Dictionary = _data.get("animations", {})
	if all.has(id):
		return all[id]
	if all.has("idle"):
		return all.idle
	return {"start": 0, "frames": 1, "fps": 4, "loop": true, "hold": 1.5}


static func hold_of(id: String) -> float:
	return clampf(float(anim(id).get("hold", 1.5)), 1.0, 3.0)


static func frame_rect(index: int) -> Rect2:
	ensure()
	var size: Array = _data.get("frame_size", [32, 48])
	var width := int(size[0])
	var height := int(size[1])
	var columns := maxi(1, int(_data.get("columns", 8)))
	var column := index % columns
	var row := int(index / columns)
	return Rect2(column * width, row * height, width, height)


static func grey_for(stage: String) -> float:
	match stage:
		"middle_aged":
			return 0.22
		"elderly":
			return 0.62
		"very_elderly":
			return 0.88
		_:
			return 0.0


static func bake(stage: String, appearance: Dictionary) -> Texture2D:
	var look := _look(appearance)
	var key := "body|%s|%s|%s|%s|%s" % [stage, look.skin, look.hair, look.eyes, str(grey_for(stage))]
	if _baked.has(key):
		return _baked[key]
	var image := _load_image(sheet_path(stage))
	if image == null:
		image = _fallback_image(32, 48, SKINS.get(look.skin, SKINS.fair))
	else:
		image = image.duplicate()
		_recolour(image, look, grey_for(stage))
	var texture := ImageTexture.create_from_image(image)
	_baked[key] = texture
	return texture


static func bake_portrait(appearance: Dictionary) -> Texture2D:
	var look := _look(appearance)
	var key := "face|%s|%s|%s" % [look.skin, look.hair, look.eyes]
	if _baked.has(key):
		return _baked[key]
	var image := _load_image("res://assets/npcs/portrait.png")
	if image == null:
		image = _fallback_image(32, 32, SKINS.get(look.skin, SKINS.fair))
	else:
		image = image.duplicate()
		_recolour(image, look, 0.0)
	var texture := ImageTexture.create_from_image(image)
	_baked[key] = texture
	return texture


static func background(id: String) -> Texture2D:
	var name := id if id != "" else "home"
	if _backgrounds.has(name):
		return _backgrounds[name]
	var image := _load_image("res://assets/backgrounds/%s.png" % name)
	if image == null:
		image = _fallback_image(180, 120, Color("6d8fbf"))
	var texture := ImageTexture.create_from_image(image)
	_backgrounds[name] = texture
	return texture


static func _look(appearance: Dictionary) -> Dictionary:
	var skin := str(appearance.get("skin", "fair"))
	var hair := str(appearance.get("hair_color", "brown"))
	var eyes := str(appearance.get("eyes", "brown"))
	if not SKINS.has(skin):
		skin = "fair"
	if not HAIR.has(hair):
		hair = "brown"
	if not EYES.has(eyes):
		eyes = "brown"
	return {"skin": skin, "hair": hair, "eyes": eyes}


static func _recolour(image: Image, look: Dictionary, grey: float) -> void:
	var skin: Color = SKINS[look.skin]
	var hair: Color = HAIR[look.hair].lerp(Color("c8c8cc"), grey)
	var eyes: Color = EYES[look.eyes]
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.05:
				continue
			if _near(pixel, SKIN_KEY):
				image.set_pixel(x, y, Color(skin.r, skin.g, skin.b, pixel.a))
			elif _near(pixel, HAIR_KEY):
				image.set_pixel(x, y, Color(hair.r, hair.g, hair.b, pixel.a))
			elif _near(pixel, EYE_KEY):
				image.set_pixel(x, y, Color(eyes.r, eyes.g, eyes.b, pixel.a))


static func _near(pixel: Color, key: Color) -> bool:
	return absf(pixel.r - key.r) < 0.05 and absf(pixel.g - key.g) < 0.05 and absf(pixel.b - key.b) < 0.05


static func _load_image(path: String) -> Image:
	if ResourceLoader.exists(path):
		var resource: Resource = load(path)
		if resource is Texture2D:
			var copy := (resource as Texture2D).get_image()
			if copy != null:
				return copy
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	var err := image.load(path)
	if err != OK:
		return null
	return image


static func _fallback_image(width: int, height: int, color: Color) -> Image:
	var image := Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for y in range(4, height - 4):
		for x in range(8, width - 8):
			image.set_pixel(x, y, color)
	return image
