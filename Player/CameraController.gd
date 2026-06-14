extends Node3D
class_name CameraController

@export var head_bob_intensity: float = 0.05
@export var head_bob_speed:     float = 14.0
@export var mouse_sensitivity:  float = 0.002

@onready var camera: Camera3D = $Camera3D

var head_bob_time:      float = 0.0
var camera_default_height: float = 0.0

var _target_h_rotation:  float = 0.0
var _target_v_rotation:  float = 0.0
var _current_h_rotation: float = 0.0
var _current_v_rotation: float = 0.0

func _ready():
	camera_default_height = camera.transform.origin.y

func handle_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_target_h_rotation -= event.relative.x * mouse_sensitivity
		_target_v_rotation -= event.relative.y * mouse_sensitivity
		_target_v_rotation = clamp(_target_v_rotation, deg_to_rad(-89.0), deg_to_rad(89.0))

func update_rotation(_delta: float):
	_current_h_rotation = lerp(_current_h_rotation, _target_h_rotation, 0.2)
	_current_v_rotation = lerp(_current_v_rotation, _target_v_rotation, 0.2)
	camera.rotation.x = _current_v_rotation

func get_h_rotation() -> float:
	return _current_h_rotation

func update_head_bob(delta: float, moving: bool, grounded: bool):
	if moving and grounded:
		head_bob_time += delta * head_bob_speed
		var vertical   = sin(head_bob_time) * head_bob_intensity
		var horizontal = cos(head_bob_time * 0.5) * head_bob_intensity
		camera.transform.origin = Vector3(horizontal, camera_default_height + vertical, 0)
	else:
		head_bob_time = 0
		camera.transform.origin = Vector3(0, camera_default_height, 0)

func get_camera() -> Camera3D:
	return camera

func get_camera_forward() -> Vector3:
	return -camera.global_transform.basis.z
