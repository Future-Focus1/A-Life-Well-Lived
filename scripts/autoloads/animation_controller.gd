extends Node

## Maps an animation id to frames. Missing art returns a stand-in texture.


func definition(id: String) -> Dictionary:
	return SpriteBank.anim(id)


func sheet_for_stage(stage: String) -> String:
	return SpriteBank.sheet_path(stage)


func texture_for(stage: String, appearance: Dictionary) -> Texture2D:
	return SpriteBank.bake(stage, appearance)
