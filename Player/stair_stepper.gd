extends Node

const MAX_STEP_HEIGHT:        float = 0.5
const STAIR_SNAP_COOLDOWN:    float = 0.01
const STAIR_SNAP_DOWN_FRAMES: int   = 3
const CAMERA_RETURN_SPEED:    float = 12.0

var _stair_snap_cooldown:          float = 0.0
var _snapped_to_stairs_last_frame: bool  = false
var _last_frame_was_on_floor:      int   = -INF
var _saved_camera_global_pos              = null

# Ссылки устанавливаются через initialize()
var _body:   CharacterBody3D = null
var _camera: Camera3D        = null

func initialize(body: CharacterBody3D, camera: Camera3D) -> void:
	_body   = body
	_camera = camera

# Вызывать в _physics_process игрока ВМЕСТО move_and_slide()
# Возвращает true если снап вверх сработал (move_and_slide уже вызван внутри)
# Возвращает false — тогда игрок сам вызывает move_and_slide()
func process_stairs(delta: float, wish_dir: Vector3, move_speed: float) -> bool:
	_stair_snap_cooldown = max(_stair_snap_cooldown - delta, 0.0)

	# Обновляем last_frame_was_on_floor здесь, чтобы не дублировать в игроке
	if _body.is_on_floor():
		_last_frame_was_on_floor = Engine.get_physics_frames()

	if not _snap_up_stairs_check(delta, wish_dir, move_speed):
		_body.move_and_slide()
		_snap_down_to_stairs_check()
		return false

	return true

# Вызывать в _process игрока для плавного возврата камеры
func process_camera_smooth(delta: float, move_speed: float) -> void:
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

func _snap_up_stairs_check(delta: float, wish_dir: Vector3, move_speed: float) -> bool:
	if _stair_snap_cooldown > 0:
		return false
	if not _body.is_on_floor() and not _snapped_to_stairs_last_frame:
		return false
	if _body.velocity.y > 0:
		return false

	var move_dir = wish_dir if wish_dir.length() > 0.1 \
				 else (_body.velocity * Vector3(1, 0, 1)).normalized()
	if move_dir.length() < 0.1:
		return false

	var expected   = move_dir * move_speed * delta
	var low_result = PhysicsTestMotionResult3D.new()
	if not _run_body_test_motion(_body.global_transform, expected * Vector3(1, 0, 1), low_result):
		return false

	var contact_normal = low_result.get_collision_normal()
	if abs(contact_normal.y) > 0.7:
		return false

	var step_pos    = _body.global_transform.translated(expected + Vector3(0, MAX_STEP_HEIGHT * 2, 0))
	var down_result = KinematicCollision3D.new()
	if not _body.test_move(step_pos, Vector3(0, -MAX_STEP_HEIGHT * 2, 0), down_result):
		return false

	var col = down_result.get_collider()
	if not (col.is_class("StaticBody3D") or col.is_class("CSGShape3D")):
		return false

	var step_h = ((step_pos.origin + down_result.get_travel()) - _body.global_position).y
	if step_h > MAX_STEP_HEIGHT or step_h <= 0.01:
		return false
	if (down_result.get_position() - _body.global_position).y > MAX_STEP_HEIGHT:
		return false

	_save_camera_pos_for_smoothing()
	_body.global_position = step_pos.origin + down_result.get_travel()
	_body.apply_floor_snap()
	_stair_snap_cooldown          = STAIR_SNAP_COOLDOWN
	_snapped_to_stairs_last_frame = true
	return true

func _snap_down_to_stairs_check() -> void:
	var did_snap          = false
	var was_on_floor_last = Engine.get_physics_frames() - _last_frame_was_on_floor <= STAIR_SNAP_DOWN_FRAMES

	if not _body.is_on_floor() and _body.velocity.y <= 0 \
	and (was_on_floor_last or _snapped_to_stairs_last_frame):
		var result = PhysicsTestMotionResult3D.new()
		if _run_body_test_motion(_body.global_transform, Vector3(0, -MAX_STEP_HEIGHT, 0), result):
			_save_camera_pos_for_smoothing()
			_body.position.y += result.get_travel().y
			_body.apply_floor_snap()
			did_snap = true

	_snapped_to_stairs_last_frame = did_snap

func _save_camera_pos_for_smoothing() -> void:
	if _saved_camera_global_pos == null:
		_saved_camera_global_pos = _camera.global_position

func _run_body_test_motion(from: Transform3D, motion: Vector3, result = null) -> bool:
	if not result:
		result = PhysicsTestMotionResult3D.new()
	var params    = PhysicsTestMotionParameters3D.new()
	params.from   = from
	params.motion = motion
	return PhysicsServer3D.body_test_motion(_body.get_rid(), params, result)
