extends Panel

@export var task_item_scene: PackedScene
@export var task_container: VBoxContainer

var tasks: Array = [
	{"id": "crowbar", "label": "Сделать монтировку", "done": false},
	{"id": "still", "label": "Построить самогонный аппарат", "done": false},
	{"id": "generator", "label": "Построить генератор", "done": false},
	{"id": "cable_pole", "label": "Построить кабельную опору", "done": false},
	{"id": "derad", "label": "Построить дерадиатор", "done": false},
	{"id": "beacon", "label": "Построить маяк", "done": false},
]

var task_items: Dictionary = {}

func _ready():
	visible = false
	_build_list()
	
	# Подключаемся к сигналу BuildingSystem
	await get_tree().process_frame
	var building_system = get_tree().get_first_node_in_group("building_system")
	if building_system:
		building_system.building_built.connect(_on_building_built)
	
	# Подключаемся к сигналу инвентаря (для монтировки)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.inventory:
		player.inventory.item_added.connect(_on_item_added)

func _on_building_built(blueprint_id: String):
	# Обновляем только задачу, которая относится к этой постройке
	for task in tasks:
		if task["id"] == blueprint_id:
			task["done"] = true
			if task_items.has(blueprint_id):
				task_items[blueprint_id].update_status(true)
			break
	
	# Если маяк построен — обновляем всё (для уверенности)
	if blueprint_id == "beacon":
		update_all_tasks()

func _on_item_added(item_id: int, _amount: int):
	if item_id == 11:  # Монтировка
		for task in tasks:
			if task["id"] == "crowbar":
				task["done"] = true
				if task_items.has("crowbar"):
					task_items["crowbar"].update_status(true)
				break

func _build_list():
	for task in tasks:
		var item = task_item_scene.instantiate()
		task_container.add_child(item)
		item.setup(task["label"], task["done"])
		task_items[task["id"]] = item

func show_checklist():
	visible = true
	update_all_tasks()

func hide_checklist():
	visible = false

func toggle():
	visible = not visible
	if visible:
		update_all_tasks()

func update_all_tasks():
	for task in tasks:
		var done = _check_task(task["id"])
		task["done"] = done
		if task_items.has(task["id"]):
			task_items[task["id"]].update_status(done)

func _check_task(task_id: String) -> bool:
	match task_id:
		"crowbar":
			return _has_item(11)
		"still":
			return _has_building("still")
		"generator":
			return _has_building("generator")
		"cable_pole":
			return _has_building("cable_pole")
		"derad":
			return _has_building("derad")
		"beacon":
			return _has_building("beacon")
	return false

func _has_item(item_id: int) -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not player.inventory:
		return false
	return player.inventory.get_item_count(item_id) > 0

func _has_building(blueprint_id: String) -> bool:
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	if not blueprint:
		return false
	
	var buildings = get_tree().get_nodes_in_group("buildings")
	for building in buildings:
		if building.scene_file_path == blueprint.building_scene.resource_path:
			return true
	return false
