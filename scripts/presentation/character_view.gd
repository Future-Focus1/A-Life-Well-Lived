class_name CharacterView
extends TextureRect

var _anim := ""
var _stage := ""
var _look: Dictionary = {}
var _portrait := false
var _time := 0.0
var _def: Dictionary = {}
var _atlas: AtlasTexture
var _base: Texture2D


func _ready() -> void:
	_prepare()


func _prepare() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _atlas == null:
		_atlas = AtlasTexture.new()
		texture = _atlas


func show_person(stage: String, appearance: Dictionary, anim_id: String, portrait: bool = false) -> void:
	_prepare()
	var next := anim_id if anim_id != "" else "idle"
	if _base == null or stage != _stage or appearance != _look or portrait != _portrait:
		_stage = stage
		_look = appearance.duplicate()
		_portrait = portrait
		if portrait:
			_base = SpriteBank.bake_portrait(appearance)
		else:
			_base = SpriteBank.bake(stage, appearance)
		_atlas.atlas = _base
	if next != _anim:
		_anim = next
		_time = 0.0
		_def = SpriteBank.anim(next)
	if _def.is_empty():
		_def = SpriteBank.anim(next)
	_apply_frame(0)


func _process(delta: float) -> void:
	if _portrait or _base == null or _atlas == null:
		return
	_time += delta
	var frames := maxi(1, int(_def.get("frames", 1)))
	var fps := maxf(1.0, float(_def.get("fps", 4.0)))
	var frame := 0
	if frames > 1:
		var stepped := int(_time * fps)
		if bool(_def.get("loop", true)):
			frame = stepped % frames
		else:
			frame = mini(stepped, frames - 1)
	_apply_frame(frame)


func _apply_frame(frame: int) -> void:
	_prepare()
	if _base == null:
		return
	if _portrait:
		_atlas.atlas = _base
		_atlas.region = Rect2(0, 0, _base.get_width(), _base.get_height())
		return
	var start := int(_def.get("start", 0))
	_atlas.atlas = _base
	_atlas.region = SpriteBank.frame_rect(start + frame)
