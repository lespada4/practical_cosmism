extends Node
class_name BuildingSystem

signal build_mode_toggled(enabled: bool)

@export var build_distance_min: float = 1.0
@export var build_distance_max: float = 5.0

@onready var building_ui: Control = $"../UI_LAYER/Control/BuildingUI"
@onready var building_name: Label = $"../UI_LAYER/Control/BuildingUI/Panel/BUILDING_NAME"
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

var available_blueprints: Array[String] = ["still", "generator", "cable_pole"]
var current_index: int = 0

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
	
	if current_ghost:
		var old_transform = current_ghost.global_transform
		var old_rotation = current_ghost.rotation
		current_ghost.queue_free()
		
		current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
		player.add_child(current_ghost)
		current_ghost.setup(blueprint, player_inventory)
		current_ghost.global_transform = old_transform
		current_ghost.rotation = old_rotation

func toggle_build_mode():
	if not is_build_mode:
		_show_hint(true)
		enter_build_mode(available_blueprints[current_index])
	else:
		exit_build_mode()

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
	
	current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
	player.add_child(current_ghost)
	current_ghost.setup(blueprint, player_inventory)
	
	if building_ui:
		building_ui.visible = true
		if building_name:
			building_name.text = blueprint.display_name
	
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
		return false
	
	var blueprint = BlueprintRegistry.get_blueprint(current_blueprint_id)
	
	if not inventory.has_items(blueprint.build_costs):
		return false
	
	inventory.consume_items(blueprint.build_costs)
	
	var building = blueprint.building_scene.instantiate()
	building.global_transform = current_ghost.global_transform
	building.rotation = current_ghost.rotation
	building.position.y -= 0.2
	player.get_parent().add_child(building)
	
	exit_build_mode()
	return true

func update_build_distance_by_camera():
	if not camera:
		return
	var t = (camera.rotation.x + 1.5) / 3.0
	t = clamp(t, 0.0, 1.0)
	build_distance = lerp(build_distance_min, build_distance_max, t)
