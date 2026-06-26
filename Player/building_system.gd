extends Node
class_name BuildingSystem

signal build_mode_toggled(enabled: bool)
signal building_built(blueprint_id: String)

@export var build_distance_min: float = 1.0
@export var build_distance_max: float = 5.0

@onready var building_ui: Control = $"../UI_LAYER/Control/BuildingUI"
@onready var building_name: Label = $"../UI_LAYER/Control/BuildingUI/Panel/BUILDING_NAME"
@onready var building_cost: Label = $"../UI_LAYER/Control/BuildingUI/BUILDING_COST"
@onready var prev_arrow: Button = $"../UI_LAYER/Control/BuildingUI/SwitchBetweenBuildings/<"
@onready var next_arrow: Button = $"../UI_LAYER/Control/BuildingUI/SwitchBetweenBuildings/>"

var is_build_mode: bool = false
var is_camera_locked: bool = true
var current_ghost: Area3D = null
var current_blueprint_id: String = ""
var build_distance: float = 3.0

var player: CharacterBody3D
var camera: Camera3D
var crosshair: TextureRect
var player_inventory: Inventory = null

var available_blueprints: Array[String] = ["still", "generator", "cable_pole", "derad"]
var current_index: int = 0

const CROWBAR_ID = 11

func initialize(player_node: CharacterBody3D, camera_node: Camera3D, crosshair_node: TextureRect):
	player = player_node
	camera = camera_node
	crosshair = crosshair_node
	player_inventory = player_node.inventory
	
	if building_ui:
		building_ui.visible = false
		
		if prev_arrow:
			prev_arrow.pressed.connect(_on_prev_pressed)
		if next_arrow:
			next_arrow.pressed.connect(_on_next_pressed)
		
		_setup_ui_mouse_filter()

func _setup_ui_mouse_filter():
	for button in [prev_arrow, next_arrow]:
		if button:
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.focus_mode = Control.FOCUS_NONE

func _input(event: InputEvent):
	if event.is_action_pressed("build_mode"):
		toggle_build_mode()
	
	if is_build_mode:
		if event.is_action_pressed("ui_left"):
			_switch_to_prev()
		elif event.is_action_pressed("ui_right"):
			_switch_to_next()
		
		if event.is_action_pressed("switch_camera_buildmode"):
			_toggle_camera_mode()
		
		if event.is_action_pressed("rotate_building") and current_ghost:
			current_ghost.rotate_y(deg_to_rad(45))

func _has_crowbar() -> bool:
	if not player or not player.inventory:
		return false
	return player.inventory.get_item_count(CROWBAR_ID) > 0

func _get_blueprint_id(building: Node) -> String:
	for id in available_blueprints:
		var blueprint = BlueprintRegistry.get_blueprint(id)
		if not blueprint:
			continue
		if building.scene_file_path == blueprint.building_scene.resource_path:
			return id
	return ""

func toggle_build_mode():
	if not _has_crowbar():
		_show_no_crowbar_message()
		return
	
	if not is_build_mode:
		# Закрываем все UI при входе в стройку
		var ui_manager = player.get_node("UI_LAYER/Control/UI_Manager")
		if ui_manager and ui_manager.has_method("close_current"):
			ui_manager.close_current()
		
		_show_hint(true)
		enter_build_mode(available_blueprints[current_index])
	else:
		exit_build_mode()

func _show_no_crowbar_message():
	var hint_label = $"../UI_LAYER/Control/hint_label"
	if hint_label:
		hint_label.text = "НУЖНА МОНТИРОВКА ДЛЯ СТРОИТЕЛЬСТВА"
		hint_label.visible = true
		await get_tree().create_timer(2.0).timeout
		hint_label.visible = false

func try_deconstruct(target: Node) -> bool:
	if not _has_crowbar():
		return false
	
	if not target.has_method("deconstruct"):
		return false
	
	target.deconstruct(player)
	return true

func _switch_to_prev():
	current_index = (current_index - 1 + available_blueprints.size()) % available_blueprints.size()
	_switch_blueprint(current_index)

func _switch_to_next():
	current_index = (current_index + 1) % available_blueprints.size()
	_switch_blueprint(current_index)

func _toggle_camera_mode():
	is_camera_locked = not is_camera_locked
	
	if is_camera_locked:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if prev_arrow:
			prev_arrow.disabled = false
			prev_arrow.focus_mode = Control.FOCUS_NONE
		if next_arrow:
			next_arrow.disabled = false
			next_arrow.focus_mode = Control.FOCUS_NONE
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if prev_arrow:
			prev_arrow.disabled = false
			prev_arrow.focus_mode = Control.FOCUS_ALL
		if next_arrow:
			next_arrow.disabled = false
			next_arrow.focus_mode = Control.FOCUS_ALL

func _on_prev_pressed():
	if not is_camera_locked:
		_switch_to_prev()

func _on_next_pressed():
	if not is_camera_locked:
		_switch_to_next()

func _switch_blueprint(index: int):
	var new_blueprint_id = available_blueprints[index]
	var blueprint = BlueprintRegistry.get_blueprint(new_blueprint_id)
	if not blueprint:
		return
	
	current_blueprint_id = new_blueprint_id
	
	if building_name:
		building_name.text = blueprint.display_name
	
	if building_cost:
		building_cost.text = _format_cost(blueprint.build_costs)
	
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
	player.add_child(current_ghost)
	current_ghost.setup(blueprint, player_inventory)
	
	if camera:
		var forward = -camera.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()
		current_ghost.global_position = camera.global_position + forward * build_distance

func _format_cost(costs: Dictionary) -> String:
	print("=== _format_cost ===")
	for item_id in costs:
		var item = ItemRegistry.get_item(item_id)
		print("ID: ", item_id, " Item: ", item)
	
	var parts = []
	for item_id in costs:
		var item = ItemRegistry.get_item(item_id)
		var item_name = item.display_name if item else "Неизвестно (ID: " + str(item_id) + ")"
		parts.append(str(costs[item_id]) + " " + item_name)
	return "Стоимость: " + ", ".join(parts)

func _show_hint(show: bool):
	var hint_label = $"../UI_LAYER/Control/hint_label"
	if hint_label:
		hint_label.text = "ЧТОБЫ ПОСТРОИТЬ НАЖМИ E\n\n← → ДЛЯ ВЫБОРА ПОСТРОЙКИ\nR ДЛЯ ПОВОРОТА\nT ДЛЯ ПЕРЕКЛЮЧЕНИЯ КУРСОРА"
		hint_label.visible = show

func enter_build_mode(blueprint_id: String):
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	if not blueprint:
		return
	
	current_blueprint_id = blueprint_id
	is_build_mode = true
	is_camera_locked = true
	build_distance = 3.0
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
	player.add_child(current_ghost)
	current_ghost.setup(blueprint, player_inventory)
	
	if building_ui:
		building_ui.visible = true
		if building_name:
			building_name.text = blueprint.display_name
		if building_cost:
			building_cost.text = _format_cost(blueprint.build_costs)
	
	if crosshair:
		crosshair.visible = false
	
	build_mode_toggled.emit(true)

func exit_build_mode():
	_show_hint(false)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	is_camera_locked = true
	
	if building_ui:
		building_ui.visible = false
	
	if current_ghost:
		current_ghost.queue_free()
		current_ghost = null
	
	is_build_mode = false
	current_blueprint_id = ""
	
	if crosshair:
		crosshair.visible = true
	
	build_mode_toggled.emit(false)

func update_ghost_position():
	if not is_build_mode or not current_ghost or not camera:
		return
	
	var forward = -camera.global_transform.basis.z
	forward.y = 0
	forward = forward.normalized()
	
	current_ghost.global_position = camera.global_position + forward * build_distance

func try_build(inventory: Inventory) -> bool:
	if not is_build_mode or not current_ghost or not current_ghost.get_valid():
		print("Build failed: invalid state")
		return false
	
	var blueprint = BlueprintRegistry.get_blueprint(current_blueprint_id)
	if not blueprint:
		print("Build failed: blueprint not found")
		return false
	
	print("=== TRY BUILD ===")
	print("Blueprint ID: ", current_blueprint_id)
	print("Ghost rotation: ", current_ghost.rotation)
	print("Ghost rotation_degrees: ", current_ghost.rotation_degrees)
	print("Ghost global_transform: ", current_ghost.global_transform)
	
	if not inventory.has_items(blueprint.build_costs):
		print("Build failed: not enough resources")
		return false
	
	inventory.consume_items(blueprint.build_costs)
	
	var building = blueprint.building_scene.instantiate()
	
	# Сначала добавляем в дерево
	player.get_parent().add_child(building)
	
	# Теперь устанавливаем глобальный трансформ (работает, так как узел в дереве)
	building.global_transform = current_ghost.global_transform
	
	print("Building rotation: ", building.rotation)
	print("Building global_transform: ", building.global_transform)
	
	building.position.y -= 0.2
	building.add_to_group("buildings")
	
	if building.is_in_group("derad_zones"):
		var health_system = player.get_node("HealthSystem")
		if health_system and health_system.has_method("_connect_to_zone"):
			health_system._connect_to_zone(building)
			print("DeRad connected to HealthSystem on build")
	
	building_built.emit(current_blueprint_id)
	
	exit_build_mode()
	return true

func update_build_distance_by_camera():
	if not camera:
		return
	var t = (camera.rotation.x + 1.5) / 3.0
	t = clamp(t, 0.0, 1.0)
	build_distance = lerp(build_distance_min, build_distance_max, t)
