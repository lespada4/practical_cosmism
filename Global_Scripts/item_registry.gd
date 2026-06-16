extends Node

var items: Dictionary = {}
var items_by_name: Dictionary = {}

func _ready():
	load_all_items()

func load_all_items():
	var dir_path = "res://items/item_resources/"
	_load_items_recursive(dir_path)

func _load_items_recursive(path: String):
	var dir = DirAccess.open(path)
	if not dir:
		return
	
	var files = dir.get_files()
	for file in files:
		if file.ends_with(".tres") or file.ends_with(".res"):
			var full_path = path + file
			var item = ResourceLoader.load(full_path) as Item
			if item:
				register_item(item)
	
	var subdirs = dir.get_directories()
	for subdir in subdirs:
		_load_items_recursive(path + subdir + "/")

func register_item(item: Item):
	items[item.id] = item
	items_by_name[item.display_name.to_lower()] = item.id

func get_item(item_id: int) -> Item:
	return items.get(item_id)

func get_item_by_name(item_name: String) -> Item:
	var id = items_by_name.get(item_name.to_lower())
	return items.get(id) if id else null

func get_id_by_name(item_name: String) -> int:
	return items_by_name.get(item_name.to_lower(), -1)
