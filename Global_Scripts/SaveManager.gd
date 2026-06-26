# SaveManager.gd
extends Node

signal save_loaded(data: Dictionary)

var save_path: String = "user://save_data.tres"
var current_save: Dictionary = {}

func save_game(data: Dictionary):
	current_save = data
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))

func save_world_state(state_data: Dictionary):
	if not current_save.has("world_state"):
		current_save["world_state"] = {}
	for key in state_data:
		current_save["world_state"][key] = state_data[key]
	save_game(current_save)

func load_game() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var file = FileAccess.open(save_path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data:
			current_save = data
			return data
	return {}

func delete_save():
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		current_save = {}

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func get_current_save() -> Dictionary:
	return current_save
