extends Area3D

var blueprint: Blueprint
var is_valid: bool = true
@onready var ground_checker: RayCast3D = $RayCast3D

func setup(bp: Blueprint):
	blueprint = bp
	
	var building = bp.building_scene.instantiate()
	copy_all_meshes(building)
	
	var collision_shape = building.get_node("CollisionShape3D")
	if collision_shape and collision_shape.shape:
		$CollisionShape3D.shape = collision_shape.shape
	
	building.queue_free()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	apply_materials()
	
	await get_tree().process_frame
	check_initial_overlap()

func _physics_process(delta):
	ground_checker.force_raycast_update()
	if ground_checker.is_colliding():
		var hit = ground_checker.get_collision_point()
		global_position.y = hit.y
	else:
		is_valid = false
		update_all_colors(Color(1, 0, 0, 0.5))

func copy_all_meshes(source: Node):
	var meshes = find_all_mesh_instances(source)
	for mesh_instance in meshes:
		var new_mesh_instance = MeshInstance3D.new()
		new_mesh_instance.mesh = mesh_instance.mesh
		new_mesh_instance.transform = mesh_instance.transform
		add_child(new_mesh_instance)

func find_all_mesh_instances(node: Node) -> Array:
	var result: Array = []
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child)
		result.append_array(find_all_mesh_instances(child))
	return result

func check_initial_overlap():
	var overlapping = get_overlapping_bodies()
	var has_collision = false
	for body in overlapping:
		if not body.is_in_group("player"):
			has_collision = true
			break
	
	is_valid = not has_collision
	update_all_colors(Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5))

func _on_body_entered(body):
	if body.is_in_group("player"):
		return
	is_valid = false
	update_all_colors(Color(1, 0, 0, 0.5))

func _on_body_exited(body):
	if body.is_in_group("player"):
		return
	var overlapping = get_overlapping_bodies()
	for b in overlapping:
		if not b.is_in_group("player"):
			return
	is_valid = true
	update_all_colors(Color(0, 1, 0, 0.5))

func apply_materials():
	for child in get_children():
		if child is MeshInstance3D:
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0, 1, 0, 0.5)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			child.material_override = mat

func update_all_colors(color: Color):
	for child in get_children():
		if child is MeshInstance3D and child.material_override:
			child.material_override.albedo_color = color

func get_valid() -> bool:
	return is_valid
