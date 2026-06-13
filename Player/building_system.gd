extends Node
class_name BuildingSystem

signal build_mode_toggled(enabled: bool)

@export var build_distance_min: float = 1.0
@export var build_distance_max: float = 5.0

var is_build_mode: bool = false
var current_ghost: Area3D = null
var current_blueprint_id: String = ""
var build_distance: float = 3.0

var player: CharacterBody3D
var camera: Camera3D
var crosshair: TextureRect

func initialize(player_node: CharacterBody3D, camera_node: Camera3D, crosshair_node: TextureRect):
	player = player_node
	camera = camera_node
	crosshair = crosshair_node

func _input(event: InputEvent):
	if event.is_action_pressed("build_mode"):
		toggle_build_mode()
	
	if is_build_mode and event.is_action_pressed("rotate_building") and current_ghost:
		current_ghost.rotate_y(deg_to_rad(45))

func toggle_build_mode():
	if not is_build_mode:
		enter_build_mode("still")
	else:
		exit_build_mode()

func enter_build_mode(blueprint_id: String):
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	if not blueprint:
		return
	
	current_blueprint_id = blueprint_id
	is_build_mode = true
	build_distance = 3.0
	
	current_ghost = preload("res://blueprints/ghost/ghost.tscn").instantiate()
	player.add_child(current_ghost)
	current_ghost.setup(blueprint)
	
	if crosshair:
		crosshair.visible = false
	
	build_mode_toggled.emit(true)

func exit_build_mode():
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
