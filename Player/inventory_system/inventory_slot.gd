extends Panel

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count

var slot_index: int = -1
var item_id: int = -1
var quantity: int = 0
var is_hotbar_slot: bool = false

func set_slot(index: int, item: int, amount: int, hotbar: bool = false):
	slot_index = index
	item_id = item
	quantity = amount
	is_hotbar_slot = hotbar
	
	icon.texture = null
	count_label.text = ""
	
	if item_id == -1 or item_id == 0:
		return
	
	var item_resource = ItemRegistry.get_item(item_id)
	if item_resource and item_resource.icon:
		icon.texture = item_resource.icon
	
	count_label.text = str(amount) if amount > 1 else ""

func clear_slot():
	item_id = -1
	quantity = 0
	icon.texture = null
	count_label.text = ""

func is_empty() -> bool:
	return item_id == -1

func _get_drag_data(_at_position):
	print("_get_drag_data: is_hotbar_slot=", is_hotbar_slot)
	if is_empty():
		return null
	
	var preview_texture = TextureRect.new()
	preview_texture.texture = icon.texture
	preview_texture.size = Vector2(64, 64)
	
	var drag_data = {
		"from_hotbar": is_hotbar_slot,
		"from_slot": slot_index,
		"item_id": item_id,
		"quantity": quantity
	}
	
	set_drag_preview(preview_texture)
	return drag_data

func _can_drop_data(_at_position, _data):
	return true

func _drop_data(_at_position, data):
	if not data.has("from_slot"):
		return
	
	var target_inventory = get_inventory_reference()
	if not target_inventory:
		return
	
	var from_hotbar = data["from_hotbar"]
	var from_slot = data["from_slot"]
	
	target_inventory.swap_slots(from_hotbar, from_slot, is_hotbar_slot, slot_index)
	
	# Обновляем UI
	var parent = get_parent()
	while parent:
		if parent.has_method("update_inventory"):
			parent.update_inventory()
			break
		parent = parent.get_parent()
	
	# Обновляем хотбар
	var hotbar = get_tree().get_first_node_in_group("hotbar")
	if hotbar and hotbar.has_method("update_hotbar"):
		hotbar.update_hotbar()

func get_inventory_reference():
	var parent = get_parent()
	while parent:
		if parent.has_method("get_inventory"):
			return parent.get_inventory()
		parent = parent.get_parent()
	return null
