extends StaticBody3D
class_name CablePole

@export var connection_radius: float = 5.0
@export var pole_connection_radius: float = 8.0
@export var is_powered: bool = false
@export var connection_point: Marker3D

var connected_poles: Array = []
var connected_consumers: Array = []
var connected_producers: Array = []

@onready var connection_area: Area3D = $ConnectionArea
@onready var pole_connection_area: Area3D = $PoleConnectionArea
@onready var power_light: MeshInstance3D = $PowerLight

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
	pole_connection_area.body_entered.connect(_on_pole_entered)
	pole_connection_area.body_exited.connect(_on_pole_exited)
	
	call_deferred("update_all_wires")

func _on_device_entered(body):
	var consumer = _get_consumer(body)
	if consumer and consumer not in connected_consumers:
		connected_consumers.append(consumer)
		consumer.set_power_source(self)
		consumer.update_power_status()
	
	var producer = _get_producer(body)
	if producer and producer not in connected_producers:
		connected_producers.append(producer)
		producer.running_changed.connect(_on_producer_running_changed)
		_update_power_from_producers()

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

func _on_producer_running_changed(running: bool):
	_update_power_from_producers()

func _on_pole_entered(body):
	if body is CablePole and body != self:
		if body not in connected_poles:
			connected_poles.append(body)
			_create_wire(body)
			body._on_pole_entered(self)
			_update_power_from_poles()

func _on_pole_exited(body):
	if body is CablePole and body in connected_poles:
		connected_poles.erase(body)
		_remove_wire(body)
		_update_power_from_poles()

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

func update_all_wires():
	for pole in connected_poles:
		_create_wire(pole)
