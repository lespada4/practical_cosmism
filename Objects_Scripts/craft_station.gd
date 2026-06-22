extends StaticBody3D

@export var station_type: String = "still"
@export var connection_point: Marker3D

var is_crafting_open: bool = false
var crafting_ui_ref: Control = null
var consumer: ElectricConsumer

func _find_selected_pole_in_range() -> CablePole:
	var search_radius = 8.0
	for pole in get_tree().get_nodes_in_group("cable_poles"):
		if pole.is_selected and global_position.distance_to(pole.global_position) <= search_radius:
			return pole
	return null

func _ready():
	consumer = $ElectricConsumer

func interact(player):
	var selected_pole = _find_selected_pole_in_range()
	if selected_pole:
		selected_pole.connect_to_device(self)
		return
	
	if not consumer.has_power():
		MessageSystem.show_message("НЕТ ЭНЕРГИИ! Поставь генератор, кабельную опору и подключи их.")
		return
	
	crafting_ui_ref = player.crafting_ui
	crafting_ui_ref.open(station_type)
	is_crafting_open = true

func _process(_delta: float) -> void:
	if is_crafting_open and crafting_ui_ref and not consumer.has_power():
		crafting_ui_ref.close()
		is_crafting_open = false

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

func can_craft() -> bool:
	return consumer.has_power()
