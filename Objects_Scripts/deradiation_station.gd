extends StaticBody3D

signal player_entered_zone()
signal player_exited_zone()
signal active_state_changed(active: bool)

@export var connection_point: Marker3D
@export var radius: float = 5.0
@export var is_active: bool = false

var consumer: ElectricConsumer

@onready var area: Area3D = $Area3D
@onready var indicator: MeshInstance3D = $Indicator
@onready var particles: GPUParticles3D = $Particles

func _ready():
	consumer = $ElectricConsumer
	consumer.power_changed.connect(_on_power_changed)
	
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = radius
	area.add_child(shape)
	
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	
	area.monitoring = false
	area.monitorable = false
	
	add_to_group("derad_zones")
	_update_visual(false)

func _find_selected_pole_in_range() -> CablePole:
	var search_radius = 8.0
	for pole in get_tree().get_nodes_in_group("cable_poles"):
		if pole.is_selected and global_position.distance_to(pole.global_position) <= search_radius:
			return pole
	return null

func interact(_player):
	var selected_pole = _find_selected_pole_in_range()
	if selected_pole:
		selected_pole.connect_to_device(self)
		return

func set_power_source(source: Node):
	if consumer:
		consumer.set_power_source(source)
		consumer.update_power_status()

func update_power_status():
	if consumer:
		consumer.update_power_status()

func _on_power_changed(powered: bool):
	print("DeRad: power changed to ", powered)
	
	var was_active = is_active
	is_active = powered
	
	area.monitoring = powered
	area.monitorable = powered
	
	if was_active != is_active:
		active_state_changed.emit(is_active)
	
	_update_visual(powered)

func _update_visual(powered: bool):
	if indicator:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN if powered else Color.RED
		mat.emission_enabled = true
		mat.emission = Color.GREEN if powered else Color.RED
		indicator.material_override = mat
	
	if particles:
		particles.emitting = powered

func _on_body_entered(body):
	if body.is_in_group("player") and is_active:
		player_entered_zone.emit()

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_exited_zone.emit()

func is_player_in_zone(player: Node) -> bool:
	if not player:
		return false
	if not area.monitoring:
		return false
	var bodies = area.get_overlapping_bodies()
	return player in bodies

func get_connection_point() -> Marker3D:
	return connection_point

func deconstruct(player):
	var poles = get_tree().get_nodes_in_group("cable_poles")
	for pole in poles:
		if pole.has_method("_remove_device_wire"):
			pole.call("_remove_device_wire", self)
	
	var blueprint_id = BlueprintRegistry.get_blueprint_id_by_building(self)
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	
	if blueprint:
		for item_id in blueprint.build_costs:
			player.inventory.add_item(item_id, blueprint.build_costs[item_id])
	
	queue_free()
