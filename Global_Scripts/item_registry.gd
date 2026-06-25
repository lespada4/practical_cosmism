# ItemRegistry.gd (автозагрузка)
extends Node

const ITEMS = {
	3: preload("res://items/item_resources/consumables/moonshine.tres"),
	8: preload("res://items/item_resources/consumables/tarakan.tres"),
	10: preload("res://items/item_resources/resources/coal.tres"),
	12: preload("res://items/item_resources/resources/fuel.tres"),
	1: preload("res://items/item_resources/resources/iron.tres"),
	4: preload("res://items/item_resources/resources/mold.tres"),
	6: preload("res://items/item_resources/resources/molten_iron.tres"),
	7: preload("res://items/item_resources/resources/radioactive_parts.tres"),
	2: preload("res://items/item_resources/resources/steel.tres"),
	9: preload("res://items/item_resources/resources/trash.tres"),
	11: preload("res://items/item_resources/tools/crowbar.tres"),
}


var items_by_name: Dictionary = {}

func _ready():
	# Заполняем словарь по имени
	for id in ITEMS:
		var item = ITEMS[id]
		if item:
			items_by_name[item.display_name.to_lower()] = id
	print("Items registered: ", ITEMS.size())

func get_item(id: int) -> Item:
	return ITEMS.get(id)

func get_item_by_name(name: String) -> Item:
	var id = items_by_name.get(name.to_lower())
	return get_item(id)

func get_id_by_name(name: String) -> int:
	return items_by_name.get(name.to_lower(), -1)

func get_all_items() -> Array:
	return ITEMS.values()
