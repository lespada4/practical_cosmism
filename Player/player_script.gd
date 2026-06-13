extends CharacterBody3D

@export var speed = 3.0
@export var sprint_speed = 5.0
@export var jump_velocity = 5
@export var coyote_time = 0.1

@export var jump_cut_multiplier = 0.4
@export var air_control = 3
@export var acceleration = 32.0
@export var friction = 32.0
const GRAVITY_UP = 10.0
const GRAVITY_DOWN = 32.0

# ===== STAIRS =====
const MAX_STEP_HEIGHT:        float = 0.5
const STAIR_SNAP_COOLDOWN:    float = 0.01
const STAIR_SNAP_DOWN_FRAMES: int   = 3

var _stair_snap_cooldown:         float = 0.0
var _snapped_to_stairs_last_frame: bool  = false
var _last_frame_was_on_floor:      int   = -INF
var _saved_camera_global_pos              = null

# ===== NODES =====
@onready var inventory: Inventory = $Inventory
@onready var health_system: HealthSystem = $HealthSystem
@onready var building_system: Node = $BuildingSystem
@onready var camera_controller: CameraController = $CameraController
@onready var camera: Camera3D = $CameraController/Camera3D
@onready var interaction_ray: RayCast3D = $CameraController/Camera3D/interaction_ray
@onready var dropper: Marker3D = $CameraController/Camera3D/Dropper

@onready var crosshair: TextureRect = $UI_LAYER/Control/crosshair
@onready var inventory_label: Label = $UI_LAYER/Control/inventory_label
@onready var health_label: Label = $UI_LAYER/Control/health_label
@onready var radiation_label: Label = $UI_LAYER/Control/radiation_label
@onready var inventory_bar: HBoxContainer = $UI_LAYER/Control/InventoryBar
@onready var full_inventory: Panel = $UI_LAYER/Control/FullInventory
@onready var crafting_ui: Panel = $UI_LAYER/Control/craftingUI
@onready var protection_label: Label = $UI_LAYER/Control/protection_label

var coyote_timer = 0.0
var is_jumping: bool = false
var is_sprinting: bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	add_to_group("player")

	building_system.initialize(self, camera_controller.get_camera(), crosshair)

	health_system.died.connect(_on_death)
	health_system.health_changed.connect(update_health_display)
	health_system.radiation_changed.connect(update_radiation_display)

	inventory.inventory_updated.connect(_on_inventory_updated)

	inventory.add_item(1, 10)
	inventory.add_item(2, 5)
	inventory.add_item(3, 2)

	inventory.inventory_updated.connect(update_inventory_display)
	update_inventory_display()
	update_health_display(health_system.health)
	update_radiation_display(health_system.radiation, health_system.radiation_stage)
	health_system.protection_changed.connect(update_protection_display)

func _input(event):
	camera_controller.handle_input(event)

	if event is InputEventMouseMotion and building_system.is_build_mode:
		building_system.update_build_distance_by_camera()

	if event.is_action_pressed("interact"):
		if building_system.is_build_mode:
			building_system.try_build(inventory)
		else:
			try_interact()

	if event.is_action_pressed("craft"):
		crafting_ui.open("player")

	if event.is_action_pressed("sprint"):
		is_sprinting = true

	if event.is_action_released("sprint"):
		is_sprinting = false

	if event.is_action_pressed("drop_item"):
		drop_current_item()

func _physics_process(delta):
	_stair_snap_cooldown = max(_stair_snap_cooldown - delta, 0.0)

	# ===== КАМЕРА =====
	camera_controller.update_rotation(delta)

	# ===== ВВОД =====
	var input_dir = Input.get_vector("left", "right", "forward", "back")

	var camera_forward = camera_controller.get_camera_forward()
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()

	var camera_right = camera_controller.get_camera().global_transform.basis.x
	camera_right.y = 0
	camera_right = camera_right.normalized()

	var direction = (camera_forward * -input_dir.y + camera_right * input_dir.x).normalized()
	var wish_dir = direction

	# ===== СКОРОСТЬ =====
	var current_speed = sprint_speed if (is_sprinting and direction != Vector3.ZERO and is_on_floor()) else speed

	# ===== ГРАВИТАЦИЯ =====
	if not is_on_floor():
		velocity.y -= GRAVITY_DOWN * delta
	
	# ===== ПРЫЖОК =====
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# ===== ДВИЖЕНИЕ =====
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# ===== СТУПЕНЬКИ =====
	if not _snap_up_stairs_check(delta, wish_dir, current_speed):
		move_and_slide()
		_snap_down_to_stairs_check()

	# ===== ПЛАВНЫЙ ВОЗВРАТ КАМЕРЫ =====
	_slide_camera_smooth_back_to_origin(delta, current_speed)

	# ===== СИСТЕМЫ =====
	camera_controller.update_head_bob(delta, direction != Vector3.ZERO, is_on_floor())

	if building_system.is_build_mode:
		building_system.update_ghost_position()

# =====================================================
#  СИСТЕМА СТУПЕНЕК (PhysicsTestMotion — как в большом скрипте)
# =====================================================

func _snap_up_stairs_check(delta: float, wish_dir: Vector3, move_speed: float) -> bool:
	if _stair_snap_cooldown > 0:
		return false
	if not is_on_floor() and not _snapped_to_stairs_last_frame:
		return false
	if velocity.y > 0:
		return false

	var move_dir = wish_dir if wish_dir.length() > 0.1 else (velocity * Vector3(1, 0, 1)).normalized()
	if move_dir.length() < 0.1:
		return false

	var expected   = move_dir * move_speed * delta
	var low_result = PhysicsTestMotionResult3D.new()
	if not _run_body_test_motion(global_transform, expected * Vector3(1, 0, 1), low_result):
		return false

	var contact_normal = low_result.get_collision_normal()
	if abs(contact_normal.y) > 0.7:
		return false

	var step_pos    = global_transform.translated(expected + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_result = KinematicCollision3D.new()
	if not test_move(step_pos, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_result):
		return false

	var col = down_result.get_collider()
	if not (col.is_class("StaticBody3D") or col.is_class("CSGShape3D")):
		return false

	var step_h = ((step_pos.origin + down_result.get_travel()) - global_position).y
	if step_h > MAX_STEP_HEIGHT or step_h <= 0.01:
		return false
	if (down_result.get_position() - global_position).y > MAX_STEP_HEIGHT:
		return false

	_save_camera_pos_for_smoothing()
	global_position = step_pos.origin + down_result.get_travel()
	apply_floor_snap()
	_stair_snap_cooldown          = STAIR_SNAP_COOLDOWN
	_snapped_to_stairs_last_frame = true
	return true

func _snap_down_to_stairs_check() -> void:
	var did_snap          = false
	var was_on_floor_last = Engine.get_physics_frames() - _last_frame_was_on_floor <= STAIR_SNAP_DOWN_FRAMES

	if not is_on_floor() and velocity.y <= 0 and (was_on_floor_last or _snapped_to_stairs_last_frame):
		var result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), result):
			_save_camera_pos_for_smoothing()
			position.y += result.get_travel().y
			apply_floor_snap()
			did_snap = true

	if is_on_floor():
		_last_frame_was_on_floor = Engine.get_physics_frames()

	_snapped_to_stairs_last_frame = did_snap

func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result:
		result = PhysicsTestMotionResult3D.new()
	var params   = PhysicsTestMotionParameters3D.new()
	params.from  = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(get_rid(), params, result)

func is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > floor_max_angle

# =====================================================
#  СГЛАЖИВАНИЕ КАМЕРЫ НА СТУПЕНЬКАХ
# =====================================================

func _save_camera_pos_for_smoothing() -> void:
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = camera.global_position

func _slide_camera_smooth_back_to_origin(delta: float, move_speed: float) -> void:
	if _saved_camera_global_pos == null:
		return
	camera.global_position.y = _saved_camera_global_pos.y
	camera.position.y = move_toward(
		camera.position.y, 0.0,
		max(velocity.length() * delta * 2.0, move_speed * delta)
	)
	_saved_camera_global_pos = camera.global_position
	if camera.position.y == 0.0:
		_saved_camera_global_pos = null

# =====================================================
#  ОСТАЛЬНЫЕ ФУНКЦИИ
# =====================================================

func try_interact():
	if not interaction_ray.is_colliding():
		return
	var hit = interaction_ray.get_collider()
	if hit.is_in_group("resource") and hit.has_method("collect"):
		hit.collect()
	elif hit.has_method("interact"):
		hit.interact(self)

func collect_item(item_id: int, amount: int):
	inventory.add_item(item_id, amount)

func update_inventory_display():
	var iron     = inventory.get_item_count(1)
	var steel    = inventory.get_item_count(2)
	var moonshine = inventory.get_item_count(3)
	inventory_label.text = "Iron: " + str(iron) + "  Steel: " + str(steel) + "  Moonshine: " + str(moonshine)

func update_health_display(new_health: float):
	health_label.text = "HP: " + str(round(new_health)) + "%"

func update_radiation_display(radiation: float, stage: int):
	var color = Color.WHITE
	match stage:
		0: color = Color.GREEN
		1: color = Color.YELLOW
		2: color = Color.ORANGE
		3: color = Color.RED
	radiation_label.text = "Rad: " + str(round(radiation)) + "%"
	radiation_label.modulate = color

func update_protection_display(resistance: float, timer: float):
	if resistance > 0:
		var resistance_str = "%.1f" % resistance
		protection_label.text = "Prot: " + resistance_str + "% (" + str(round(timer)) + "s)"
		protection_label.visible = true
	else:
		protection_label.visible = false

func apply_damage(amount: float, damage_type: int):
	match damage_type:
		1: health_system.apply_environment_radiation(amount)
		2: health_system.apply_poison_damage(amount)

func stop_damage(damage_type: int):
	match damage_type:
		1: health_system.stop_environment_radiation()
		2: health_system.stop_poison_damage()

func _on_death():
	if get_tree():
		get_tree().reload_current_scene()

func _on_inventory_updated():
	var emission = inventory.get_total_radiation_emission()
	health_system.apply_inventory_radiation(emission)

func use_moonshine():
	health_system.use_moonshine()

func use_antirad():
	health_system.use_antirad()

func use_cockroach():
	health_system.use_cockroach()

func drop_current_item():
	if not inventory:
		return
	var active_slot = inventory_bar.active_slot
	var slot_data   = inventory.get_hotbar_slot(active_slot)
	if not slot_data or not slot_data.item:
		return
	var item_id  = slot_data.item.id
	var quantity = 1
	if inventory.remove_item(item_id, quantity):
		drop_item_in_world(item_id, quantity)

func drop_item_in_world(item_id: int, quantity: int):
	var item_resource = ItemRegistry.get_item(item_id)
	if not item_resource or not item_resource.collectable_scene:
		return
	var collectable = item_resource.collectable_scene.instantiate()
	get_parent().add_child(collectable)
	collectable.setup(item_resource, quantity)
	collectable.global_position = dropper.global_position
	var forward    = camera_controller.get_camera_forward()
	var throw_dir  = forward + Vector3(0, 0.5, 0)
	throw_dir = throw_dir.normalized()
	throw_dir.x += randf_range(-0.2, 0.2)
	throw_dir.z += randf_range(-0.2, 0.2)
	throw_dir = throw_dir.normalized()
	if collectable.has_method("apply_velocity"):
		collectable.apply_velocity(throw_dir * 6.0)

func show_demo_complete():
	print("DEMO COMPLETE! Congratulations!")
	if has_node("UI_LAYER/Control/DemoCompleteLabel"):
		$UI_LAYER/Control/DemoCompleteLabel.visible = true
		await get_tree().create_timer(3.0).timeout
		$UI_LAYER/Control/DemoCompleteLabel.visible = false
