extends StaticBody3D
class_name FuelGenerator

@export var fuel: float = 0.0
@export var max_fuel: float = 100.0
@export var fuel_consumption_rate: float = 1.0
@export var fuel_type: String = "liquid"  # "solid", "liquid", "universal"
@export var fuel_items: Array[int] = []  # ID предметов, которые можно использовать как топливо
@export var fuel_energy: float = 25.0  # Сколько энергии даёт одна единица топлива
@export var connection_point: Marker3D

@onready var energy_label: Label3D = $ENERGY_LABEL
@onready var producer: ElectricProducer = $ElectricProducer

var is_running: bool = false
var _last_fuel: float = 0.0

func _find_selected_pole_in_range() -> CablePole:
	var search_radius = 8.0
	for pole in get_tree().get_nodes_in_group("cable_poles"):
		if pole.is_selected and global_position.distance_to(pole.global_position) <= search_radius:
			return pole
	return null

func _process(delta: float) -> void:
	var was_running = is_running
	
	if fuel > 0:
		is_running = true
		fuel -= fuel_consumption_rate * delta
		if fuel < 0:
			fuel = 0
	else:
		is_running = false
	
	producer.is_running = is_running
	
	if is_running != was_running:
		_notify_poles()
	
	_update_label()

func _update_label():
	if not energy_label:
		return
	
	var fuel_percent = round((fuel / max_fuel) * 100)
	var label_text = "⚡ " + str(round(fuel)) + "/" + str(max_fuel)
	
	match fuel_type:
		"solid":
			var coal_count = int(ceil(fuel / fuel_energy))
			label_text += "\n🪨 " + str(coal_count)
		"liquid":
			label_text += "\n🛢️ " + str(round(fuel))
		"universal":
			label_text += "\n⚙️ " + str(round(fuel))
	
	energy_label.text = label_text

func _notify_poles():
	var poles = get_tree().get_nodes_in_group("cable_poles")
	for pole in poles:
		if pole.has_method("_update_power_from_producers"):
			pole._update_power_from_producers()

func interact(player) -> void:
	var selected_pole = _find_selected_pole_in_range()
	if selected_pole:
		selected_pole.connect_to_device(self)
		return
	
	# Проверяем, есть ли подходящее топливо в инвентаре
	var fuel_id = _find_fuel_in_inventory(player)
	if fuel_id != -1:
		player.inventory.remove_item(fuel_id, 1)
		fuel = min(fuel + fuel_energy, max_fuel)
		return
	
	# Если топлива нет — сообщение
	MessageSystem.show_message("Нужно топливо для генератора!", 2.0)

func _find_fuel_in_inventory(player) -> int:
	for item_id in fuel_items:
		if player.inventory.get_item_count(item_id) > 0:
			return item_id
	return -1

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
