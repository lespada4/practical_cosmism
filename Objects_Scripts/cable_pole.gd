extends StaticBody3D
class_name CablePole

@export var connection_radius: float = 5.0
@export var pole_connection_radius: float = 8.0
@export var is_powered: bool = false
@export var connection_point: Marker3D
@export var require_line_of_sight: bool = true

var connected_poles: Array = []
var connected_consumers: Array = []
var connected_producers: Array = []
var is_selected: bool = false

@onready var connection_area: Area3D = $ConnectionArea
@onready var pole_connection_area: Area3D = $PoleConnectionArea
@onready var power_light: MeshInstance3D = $PowerLight
@onready var selection_indicator: MeshInstance3D = $SelectionIndicator

func _ready():
	connection_area.body_entered.connect(_on_device_entered)
	connection_area.body_exited.connect(_on_device_exited)
	
	var shape = CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	shape.shape.radius = connection_radius
	connection_area.add_child(shape)
	
	var pole_shape = CollisionShape3D.new()
	pole_shape.shape = SphereShape3D.new()
	pole_shape.shape.radius = pole_connection_radius
	pole_connection_area.add_child(pole_shape)
	
	if selection_indicator:
		selection_indicator.visible = false
	
	call_deferred("update_all_wires")

func interact(player):
	if not player:
		return
	
	if is_selected:
		_deselect()
		return
	
	var selected_pole = _find_selected_pole_in_range()
	if selected_pole:
		_toggle_connection(selected_pole)
		selected_pole._deselect()
	else:
		_select()

func _find_selected_pole_in_range():
	for body in pole_connection_area.get_overlapping_bodies():
		if body is CablePole and body != self:
			if body.is_selected and _has_line_of_sight(body):
				return body
	return null

func _select():
	is_selected = true
	if selection_indicator:
		selection_indicator.visible = true

func _deselect():
	is_selected = false
	if selection_indicator:
		selection_indicator.visible = false

func _toggle_connection(other_pole: CablePole):
	if other_pole == self:
		return
	
	if other_pole in connected_poles:
		_remove_wire(other_pole)
		connected_poles.erase(other_pole)
		other_pole.connected_poles.erase(self)
		other_pole._remove_wire(self)
	else:
		if _has_line_of_sight(other_pole):
			connected_poles.append(other_pole)
			other_pole.connected_poles.append(self)
			_create_wire(other_pole)
			other_pole._create_wire(self)
	
	_update_power_from_poles()
	other_pole._update_power_from_poles()

func _has_line_of_sight(other_pole: CablePole) -> bool:
	if not require_line_of_sight:
		return true
	if not connection_point or not other_pole.connection_point:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var from = connection_point.global_position
	var to = other_pole.connection_point.global_position
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self, other_pole]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty()

func _on_device_entered(body):
	var consumer = _get_consumer(body)
	if consumer and consumer not in connected_consumers:
		connected_consumers.append(consumer)
		consumer.set_power_source(self)
		consumer.update_power_status()
		_create_device_wire(body)
	
	var producer = _get_producer(body)
	if producer and producer not in connected_producers:
		connected_producers.append(producer)
		producer.running_changed.connect(_on_producer_running_changed)
		_update_power_from_producers()
		_create_device_wire(body)

func _on_device_exited(body):
	var consumer = _get_consumer(body)
	if consumer in connected_consumers:
		connected_consumers.erase(consumer)
		if consumer.power_source == self:
			consumer.set_power_source(null)
			consumer.update_power_status()
	
	var producer = _get_producer(body)
	if producer in connected_producers:
		connected_producers.erase(producer)
		producer.running_changed.disconnect(_on_producer_running_changed)
		_update_power_from_producers()
	
	_remove_device_wire(body)

func _on_producer_running_changed(running: bool):
	_update_power_from_producers()

func _get_consumer(body):
	if body.has_node("ElectricConsumer"):
		return body.get_node("ElectricConsumer")
	return null

func _get_producer(body):
	if body.has_node("ElectricProducer"):
		return body.get_node("ElectricProducer")
	return null

func _update_power_from_producers():
	var has_producer = false
	for producer in connected_producers:
		if producer.is_running:
			has_producer = true
			break
	
	if has_producer:
		set_powered(true)
	else:
		_update_power_from_poles()

func _update_power_from_poles():
	var has_power_from_pole = false
	for pole in connected_poles:
		if pole.is_powered:
			has_power_from_pole = true
			break
	
	if has_power_from_pole:
		set_powered(true)
	elif connected_producers.is_empty():
		set_powered(false)

func set_powered(powered: bool):
	if is_powered == powered:
		return
	
	is_powered = powered
	
	if power_light:
		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color.GREEN if powered else Color.RED
		power_light.material_override = mat
	
	for consumer in connected_consumers:
		consumer.update_power_status()
	
	for pole in connected_poles:
		pole._update_power_from_poles()

func receive_power_from_neighbor(powered: bool):
	if powered and not is_powered:
		_update_power_from_poles()

func _create_wire(other_pole: CablePole):
	if not connection_point or not other_pole.connection_point:
		return
	
	for child in get_children():
		if child is Wire and ((child.start_point == connection_point and child.end_point == other_pole.connection_point) or
							  (child.start_point == other_pole.connection_point and child.end_point == connection_point)):
			return
	
	var wire = Wire.new()
	add_child(wire)
	wire.start_point = connection_point
	wire.end_point = other_pole.connection_point
	wire.wire_color = Color.YELLOW
	wire.wire_thickness = 0.03

func _remove_wire(other_pole: CablePole):
	for child in get_children():
		if child is Wire and ((child.start_point == connection_point and child.end_point == other_pole.connection_point) or
							  (child.start_point == other_pole.connection_point and child.end_point == connection_point)):
			child.queue_free()
			return

func _create_device_wire(device):
	if not connection_point:
		return
	
	var device_point = null
	if "connection_point" in device:
		device_point = device.connection_point
	
	if not device_point:
		return
	
	for child in get_children():
		if child is Wire and child.end_point == device_point:
			return
	
	var wire = Wire.new()
	add_child(wire)
	wire.start_point = connection_point
	wire.end_point = device_point
	wire.wire_color = Color.YELLOW
	wire.wire_thickness = 0.015

func _remove_device_wire(device):
	var device_point = null
	if "connection_point" in device:
		device_point = device.connection_point
	
	if not device_point:
		return
	
	for child in get_children():
		if child is Wire and child.end_point == device_point:
			child.queue_free()
			return

func deconstruct(player):
	var blueprint_id = BlueprintRegistry.get_blueprint_id_by_building(self)
	var blueprint = BlueprintRegistry.get_blueprint(blueprint_id)
	
	if blueprint:
		for item_id in blueprint.build_costs:
			player.inventory.add_item(item_id, blueprint.build_costs[item_id])
		
		queue_free()

func update_all_wires():
	for pole in connected_poles:
		_create_wire(pole)
