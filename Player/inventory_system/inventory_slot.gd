extends Panel

@onready var icon: TextureRect = $Icon
@onready var count_label: Label = $Count
@onready var tooltip: Label = $Tooltip

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
	tooltip.visible = false
	if item_id == -1 or item_id == 0:
		return
	var item_resource = ItemRegistry.get_item(item_id)
	if item_resource and item_resource.icon:
		icon.texture = item_resource.icon
	count_label.text = str(amount) if amount > 1 else ""
	if item_resource:
		tooltip.text = item_resource.display_name

func clear_slot():
	item_id = -1
	quantity = 0
	icon.texture = null
	count_label.text = ""
	tooltip.visible = false
	tooltip.text = ""

func is_empty() -> bool:
	return item_id == -1

func _on_mouse_entered():
	if not is_empty():
		tooltip.visible = true

func _on_mouse_exited():
	tooltip.visible = false

func _get_drag_data(_at_position):
	if is_empty():
		return null
	tooltip.visible = false
	var drag_info = {}
	if Input.is_key_pressed(KEY_SHIFT) and quantity > 1:
		var half  = int(quantity / 2.0)
		drag_info = {
			"from_hotbar": is_hotbar_slot,
			"from_slot": slot_index,
			"item_id": item_id,
			"quantity": half,
			"is_split": true
		}
		var target_inventory = get_inventory_reference()
		if target_inventory:
			if is_hotbar_slot:
				target_inventory.hotbar_slots[slot_index].quantity -= half
				if target_inventory.hotbar_slots[slot_index].quantity <= 0:
					target_inventory.hotbar_slots[slot_index] = null
			else:
				target_inventory.main_slots[slot_index].quantity -= int(half)
				if target_inventory.main_slots[slot_index].quantity <= 0:
					target_inventory.main_slots[slot_index] = null
			target_inventory.inventory_updated.emit()
		quantity -= half
		count_label.text = str(quantity) if quantity > 1 else ""
		if quantity == 0:
			clear_slot()
	else:
		drag_info = {
			"from_hotbar": is_hotbar_slot,
			"from_slot": slot_index,
			"item_id": item_id,
			"quantity": quantity,
			"is_split": false
		}
	var preview = TextureRect.new()
	preview.texture = icon.texture
	preview.size = Vector2(64, 64)
	set_drag_preview(preview)
	return drag_info

func _can_drop_data(_position, _data):
	return true

func _drop_data(_position, data):
	if not data.has("from_slot"):
		return
	var target_inventory = get_inventory_reference()
	if not target_inventory:
		return
	var from_hotbar = data["from_hotbar"]
	var from_slot = data["from_slot"]
	var drop_quantity = data["quantity"]
	var drop_item_id = data["item_id"]
	var is_split = data.get("is_split", false)
	if from_hotbar == is_hotbar_slot and from_slot == slot_index:
		return
	var ui_parent = null
	var hotbar_node = null
	if is_split:
		var target_slot = target_inventory.get_hotbar_slot(slot_index) if is_hotbar_slot else target_inventory.get_main_slot(slot_index)
		if target_slot and target_slot.item and target_slot.item.id == drop_item_id:
			var total = target_slot.quantity + drop_quantity
			var max_stack = target_slot.item.max_stack
			if total <= max_stack:
				target_slot.quantity = total
			else:
				target_slot.quantity = max_stack
		elif not target_slot:
			var new_stack = ItemStack.new()
			new_stack.item = ItemRegistry.get_item(drop_item_id)
			new_stack.quantity = drop_quantity
			if is_hotbar_slot:
				target_inventory.hotbar_slots[slot_index] = new_stack
			else:
				target_inventory.main_slots[slot_index] = new_stack
		target_inventory.inventory_updated.emit()
		ui_parent = get_parent()
		while ui_parent:
			if ui_parent.has_method("update_inventory"):
				ui_parent.update_inventory()
				break
			ui_parent = ui_parent.get_parent()
		hotbar_node = get_tree().get_first_node_in_group("hotbar")
		if hotbar_node and hotbar_node.has_method("update_hotbar"):
			hotbar_node.update_hotbar()
		return
	var from_slot_data = target_inventory.get_hotbar_slot(from_slot) if from_hotbar else target_inventory.get_main_slot(from_slot)
	var to_slot_data = target_inventory.get_hotbar_slot(slot_index) if is_hotbar_slot else target_inventory.get_main_slot(slot_index)
	if from_slot_data and from_slot_data.item and to_slot_data and to_slot_data.item and from_slot_data.item.id == to_slot_data.item.id:
		target_inventory.merge_stacks(from_slot, slot_index, from_hotbar, is_hotbar_slot)
	else:
		target_inventory.swap_slots(from_hotbar, from_slot, is_hotbar_slot, slot_index)
	ui_parent = get_parent()
	while ui_parent:
		if ui_parent.has_method("update_inventory"):
			ui_parent.update_inventory()
			break
		ui_parent = ui_parent.get_parent()
	hotbar_node = get_tree().get_first_node_in_group("hotbar")
	if hotbar_node and hotbar_node.has_method("update_hotbar"):
		hotbar_node.update_hotbar()

func get_inventory_reference():
	var parent = get_parent()
	while parent:
		if parent.has_method("get_inventory"):
			return parent.get_inventory()
		parent = parent.get_parent()
	return null
