extends StaticBody3D

@export var fuel: float = 0.0
@export var max_fuel: float = 100.0
@export var fuel_consumption_rate: float = 1.0
@export var coal_id: int = 10
@export var coal_energy: float = 25.0
@export var connection_point: Marker3D

@onready var energy_label: Label3D = $ENERGY_LABEL
@onready var producer: ElectricProducer = $ElectricProducer

var is_running: bool = false

func _find_selected_pole_in_range() -> CablePole:
	var radius = 8.0
	for pole in get_tree().get_nodes_in_group("cable_poles"):
		if pole.is_selected and global_position.distance_to(pole.global_position) <= radius:
			return pole
	return null

func _process(delta: float) -> void:
	if fuel > 0:
		is_running = true
		fuel -= fuel_consumption_rate * delta
		if fuel < 0:
			fuel = 0
	else:
		is_running = false
	
	producer.is_running = is_running
	
	if energy_label:
		var coal_count = int(ceil(fuel / coal_energy))
		energy_label.text = "ENERGY " + str(round(fuel)) + "/" + str(max_fuel) + "\nCOAL " + str(coal_count)

func interact(player) -> void:
	var selected_pole = _find_selected_pole_in_range()
	if selected_pole:
		selected_pole.connect_to_device(self)
		return
	
	if player.inventory.get_item_count(coal_id) > 0:
		player.inventory.remove_item(coal_id, 1)
		fuel = min(fuel + coal_energy, max_fuel)

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

func is_active() -> bool:
	return is_running
