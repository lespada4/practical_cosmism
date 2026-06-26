extends Node3D
class_name CameraController

@export var head_bob_intensity: float = 0.05
@export var head_bob_speed: float = 14.0
@export var mouse_sensitivity: float = 0.002

# Настройки тряски от урона
@export var hit_shake_intensity: float = 0.3
@export var hit_shake_duration: float = 0.15
@export var heavy_hit_threshold: float = 20.0
@export var heavy_hit_shake_intensity: float = 0.8

@onready var camera: Camera3D = $Camera3D
@onready var damage_overlay: ColorRect = null

var head_bob_time: float = 0.0
var camera_default_height: float = 0.0

var _target_h_rotation: float = 0.0
var _target_v_rotation: float = 0.0
var _current_h_rotation: float = 0.0
var _current_v_rotation: float = 0.0

# Тряска
var shake_intensity: float = 0.0
var shake_duration: float = 0.0
var shake_decay: float = 1.0

func _ready():
	camera_default_height = camera.transform.origin.y
	# Ищем оверлей урона
	damage_overlay = get_tree().get_first_node_in_group("damage_overlay")

func handle_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_target_h_rotation -= event.relative.x * mouse_sensitivity
		_target_v_rotation -= event.relative.y * mouse_sensitivity
		_target_v_rotation = clamp(_target_v_rotation, deg_to_rad(-89.0), deg_to_rad(89.0))

func set_initial_rotation(rotation_y: float):
	_target_h_rotation = rotation_y
	_current_h_rotation = rotation_y

func update_rotation(delta: float):
	var smoothness = 1.0 - exp(-15.0 * delta)
	_current_h_rotation = lerp(_current_h_rotation, _target_h_rotation, smoothness)
	_current_v_rotation = lerp(_current_v_rotation, _target_v_rotation, smoothness)
	camera.rotation.x = _current_v_rotation

func get_h_rotation() -> float:
	return _current_h_rotation

func update_head_bob(delta: float, moving: bool, grounded: bool):
	if moving and grounded:
		head_bob_time += delta * head_bob_speed
		var vertical = sin(head_bob_time) * head_bob_intensity
		var horizontal = cos(head_bob_time * 0.5) * head_bob_intensity
		camera.transform.origin = Vector3(horizontal, camera_default_height + vertical, 0)
	else:
		head_bob_time = 0
		camera.transform.origin = Vector3(0, camera_default_height, 0)

func get_camera() -> Camera3D:
	return camera

func get_camera_forward() -> Vector3:
	return -camera.global_transform.basis.z

# ========== ТРЯСКА ОТ УРОНА ==========

func trigger_damage_shake(damage_amount: float):
	var intensity = hit_shake_intensity
	var duration = hit_shake_duration
	
	if damage_amount >= heavy_hit_threshold:
		intensity = heavy_hit_shake_intensity
		duration = hit_shake_duration * 0.5
		# Сильный удар — дополнительная вспышка
		_flash_damage_overlay(0.5)
	else:
		_flash_damage_overlay(0.2)
	
	shake_intensity = intensity
	shake_duration = duration
	shake_decay = 1.0

func trigger_continuous_damage_shake():
	# Для радиации, отравления — лёгкая тряска
	shake_intensity = hit_shake_intensity * 0.3
	shake_duration = 0.1
	shake_decay = 0.5

func _process(delta):
	# Обновляем тряску
	if shake_duration > 0:
		var offset = Vector3(
			randf_range(-1, 1) * shake_intensity * shake_decay,
			randf_range(-1, 1) * shake_intensity * shake_decay,
			0
		)
		camera.transform.origin += offset * delta * 60
		shake_duration -= delta
		shake_decay *= 0.98
	else:
		shake_intensity = 0.0
		shake_decay = 1.0

func _flash_damage_overlay(intensity: float):
	if not damage_overlay:
		_create_damage_overlay()
	
	if damage_overlay:
		damage_overlay.color = Color(1, 0, 0, intensity)
		var tween = create_tween()
		tween.tween_property(damage_overlay, "color:a", 0.0, 0.3)

func _create_damage_overlay():
	var overlay = ColorRect.new()
	overlay.color = Color(1, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.anchor_right = 1.0
	overlay.anchor_bottom = 1.0
	overlay.z_index = 100
	add_child(overlay)
	overlay.add_to_group("damage_overlay")
	damage_overlay = overlay
