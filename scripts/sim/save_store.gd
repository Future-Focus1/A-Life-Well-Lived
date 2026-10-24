class_name SaveStore
extends RefCounted

## JSON files for one life slot, the archive, settings, and derived stats.


static func ensure(root: String) -> void:
	var folder := root.trim_suffix("/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))


static func file(root: String, name: String) -> String:
	var base := root
	if not base.ends_with("/"):
		base += "/"
	return base + name


static func write_json(path: String, data: Variant) -> bool:
	ensure(path.get_base_dir())
	var handle := FileAccess.open(path, FileAccess.WRITE)
	if handle == null:
		push_error("Could not write %s (%s)" % [path, error_string(FileAccess.get_open_error())])
		return false
	handle.store_string(JSON.stringify(data, "\t"))
	handle.close()
	return true


static func read_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var text := FileAccess.get_file_as_string(path)
	if text.strip_edges() == "":
		return null
	var parsed: Variant = JSON.parse_string(text)
	return parsed


static func remove_file(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


static func read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)
