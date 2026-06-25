@tool
extends EditorScript

func _run():
	print("ITEM REGISTRY IN PROCESS")
	
	var dir = DirAccess.open("res://items/item_resources/")
	if not dir:
		print("folder not found")
		return
	
	var items = []
	_get_all_items(dir, "res://items/item_resources/", items)
	
	# Генерируем код
	var code = "extends Node\n\nconst ITEMS = {\n"
	for item_path in items:
		var item = load(item_path)
		if item:
			code += "\t" + str(item.id) + ": preload(\"" + item_path + "\"),\n"
	code += "}\n"
	
	print(code) 
	
	var file = FileAccess.open("res://generated_item_registry.gd", FileAccess.WRITE)
	file.store_string(code)

func _get_all_items(dir: DirAccess, path: String, result: Array):
	for entry in dir.get_files():
		if entry.ends_with(".tres"):
			result.append(path + entry)
	for subdir in dir.get_directories():
		var sub = DirAccess.open(path + subdir + "/")
		if sub:
			_get_all_items(sub, path + subdir + "/", result)
