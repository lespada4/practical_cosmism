extends Node3D
class_name Wire

@export var start_point: Marker3D
@export var end_point: Marker3D
@export var wire_color: Color = Color.SADDLE_BROWN
@export var wire_thickness: float = 0.03

var line_mesh: MeshInstance3D

func _ready():
	call_deferred("create_wire")

func create_wire():
	if not start_point or not end_point:
		queue_free()
		return
	
	var start = start_point.global_position
	var end = end_point.global_position
	var length = start.distance_to(end)
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = wire_thickness
	cylinder.bottom_radius = wire_thickness
	cylinder.height = length
	
	var material = StandardMaterial3D.new()
	material.albedo_color = wire_color
	cylinder.material = material
	
	line_mesh = MeshInstance3D.new()
	line_mesh.mesh = cylinder
	add_child(line_mesh)
	
	var center = (start + end) / 2
	line_mesh.global_position = center
	
	line_mesh.look_at(end, Vector3.UP)
	line_mesh.rotate_object_local(Vector3.RIGHT, PI/2)

func update_wire():
	if line_mesh:
		line_mesh.queue_free()
	create_wire()
