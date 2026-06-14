extends Node

const MAX_STEP_HEIGHT:        float = 0.5
const STAIR_SNAP_DOWN_FRAMES: int   = 3
const CAMERA_RETURN_SPEED:    float = 12.0

var _snapped_to_stairs_last_frame: bool = false
var _last_frame_was_on_floor:      int  = -1000000
var _saved_camera_global_pos             = null

var _body:   CharacterBody3D = null
var _camera: Camera3D        = null

@onready var _stairs_ahead: RayCast3D = $"../StairsAhead"
@onready var _stairs_below: RayCast3D = $"../StairsBelow"

func initialize(body: CharacterBody3D, camera: Camera3D) -> void:
	_body   = body
	_camera = camera

func process_stairs(delta: float, _wish_dir: Vector3, _move_speed: float) -> bool:
	if _body.is_on_floor():
		_last_frame_was_on_floor = Engine.get_physics_frames()

	if not _snap_up_stairs_check(delta):
		_body.move_and_slide()
		_snap_down_to_stairs_check()
		return false

	return true

func process_camera_smooth(delta: float, _move_speed: float) -> void:
	if _saved_camera_global_pos == null:
		return
	_camera.global_position.y = _saved_camera_global_pos.y
	_camera.position.y = move_toward(
		_camera.position.y, 0.0,
		CAMERA_RETURN_SPEED * delta
	)
	_saved_camera_global_pos = _camera.global_position
	if _camera.position.y == 0.0:
		_saved_camera_global_pos = null

func is_snapped() -> bool:
	return _snapped_to_stairs_last_frame

# =====================================================
#  ВНУТРЕННИЕ МЕТОДЫ
# =====================================================

func _snap_up_stairs_check(delta: float) -> bool:
	if not _body.is_on_floor() and not _snapped_to_stairs_last_frame:
		return false
	# Если прыгаем или не двигаемся горизонтально — не проверяем
	if _body.velocity.y > 0 or (_body.velocity * Vector3(1, 0, 1)).length() == 0:
		return false

	var expected_move_motion = _body.velocity * Vector3(1, 0, 1) * delta
	var step_pos_with_clearance = _body.global_transform.translated(
		expected_move_motion + Vector3(0, MAX_STEP_HEIGHT * 2, 0)
	)

	var down_check_result = KinematicCollision3D.new()
	if not (_body.test_move(step_pos_with_clearance, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_check_result)):
		return false

	var col = down_check_result.get_collider()
	if not (col.is_class("StaticBody3D") or col.is_class("CSGShape3D")):
		return false

	var step_height = ((step_pos_with_clearance.origin + down_check_result.get_travel()) - _body.global_position).y
	if step_height > MAX_STEP_HEIGHT or step_height <= 0.01:
		return false
	if (down_check_result.get_position() - _body.global_position).y > MAX_STEP_HEIGHT:
		return false

	# Ставим StairsAhead на найденную позицию пола и проверяем что поверхность не крутая
	_stairs_ahead.global_position = down_check_result.get_position() + Vector3(0, MAX_STEP_HEIGHT, 0) + expected_move_motion.normalized() * 0.1
	_stairs_ahead.force_raycast_update()
	if not _stairs_ahead.is_colliding():
		return false
	if _is_surface_too_steep(_stairs_ahead.get_collision_normal()):
		return false

	_save_camera_pos_for_smoothing()
	_body.global_position = step_pos_with_clearance.origin + down_check_result.get_travel()
	_body.apply_floor_snap()
	_snapped_to_stairs_last_frame = true
	return true

func _snap_down_to_stairs_check() -> void:
	var did_snap          = false
	_stairs_below.force_raycast_update()
	var floor_below       = _stairs_below.is_colliding() and not _is_surface_too_steep(_stairs_below.get_collision_normal())
	var was_on_floor_last = Engine.get_physics_frames() == _last_frame_was_on_floor

	if not _body.is_on_floor() and _body.velocity.y <= 0 \
	and (was_on_floor_last or _snapped_to_stairs_last_frame) and floor_below:
		var body_test_result = KinematicCollision3D.new()
		if _body.test_move(_body.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
			_save_camera_pos_for_smoothing()
			_body.position.y += body_test_result.get_travel().y
			_body.apply_floor_snap()
			did_snap = true

	_snapped_to_stairs_last_frame = did_snap

func _save_camera_pos_for_smoothing() -> void:
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = _camera.global_position

func _is_surface_too_steep(normal: Vector3) -> bool:
	return normal.angle_to(Vector3.UP) > _body.floor_max_angle
