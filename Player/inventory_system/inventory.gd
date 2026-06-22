extends Node
class_name Inventory

signal inventory_updated
signal item_added(item_id: int, amount: int)

var hotbar_slots: Array[ItemStack] = []
var main_slots: Array[ItemStack] = []
var hotbar_size: int = 9
var main_size: int = 28

func _ready():
	clear()

func clear():
	hotbar_slots.clear()
	main_slots.clear()
	for i in range(hotbar_size):
		hotbar_slots.append(null)
	for i in range(main_size):
		main_slots.append(null)

func add_item(item_id: int, amount: int) -> bool:
	if try_add_to_slots(hotbar_slots, item_id, amount):
		item_added.emit(item_id, amount)
		return true
	if try_add_to_slots(main_slots, item_id, amount):
		item_added.emit(item_id, amount)
		return true
	return false

func try_add_to_slots(slots_array: Array, item_id: int, amount: int) -> bool:
	var item = ItemRegistry.get_item(item_id)
	if not item:
		return false
	var remaining = amount
	for i in range(slots_array.size()):
		var slot = slots_array[i]
		if slot and slot.item and slot.item.id == item_id and slot.quantity < item.max_stack:
			var space = item.max_stack - slot.quantity
			var to_add = min(space, remaining)
			slot.quantity += to_add
			remaining -= to_add
			inventory_updated.emit()
			if remaining == 0:
				return true
	for i in range(slots_array.size()):
		if slots_array[i] == null:
			var to_add = min(item.max_stack, remaining)
			var new_stack = ItemStack.new()
			new_stack.item = item
			new_stack.quantity = to_add
			slots_array[i] = new_stack
			remaining -= to_add
			inventory_updated.emit()
			if remaining == 0:
				return true
	return remaining == 0

func remove_item(item_id: int, amount: int) -> bool:
	print("remove_item called: ", item_id, " x", amount)
	var remaining = amount
	if remove_from_slots(hotbar_slots, item_id, remaining):
		return true
	if remove_from_slots(main_slots, item_id, remaining):
		return true
	return false

func remove_from_slots(slots_array: Array, item_id: int, amount: int) -> bool:
	var remaining = amount
	for i in range(slots_array.size() - 1, -1, -1):
		var slot = slots_array[i]
		if slot and slot.item and slot.item.id == item_id:
			if slot.quantity > remaining:
				slot.quantity -= remaining
				remaining = 0
				inventory_updated.emit()
				return true
			else:
				remaining -= slot.quantity
				slots_array[i] = null
	if remaining != amount:
		inventory_updated.emit()
	return remaining == 0

func swap_slots(from_hotbar: bool, from_index: int, to_hotbar: bool, to_index: int):
	var from_array = hotbar_slots if from_hotbar else main_slots
	var to_array = hotbar_slots if to_hotbar else main_slots
	var temp = from_array[from_index]
	from_array[from_index] = to_array[to_index]
	to_array[to_index] = temp
	inventory_updated.emit()

func merge_stacks(from_slot_index: int, to_slot_index: int, from_hotbar: bool, to_hotbar: bool) -> bool:
	var from_array = hotbar_slots if from_hotbar else main_slots
	var to_array = hotbar_slots if to_hotbar else main_slots
	if from_slot_index < 0 or from_slot_index >= from_array.size():
		return false
	if to_slot_index < 0 or to_slot_index >= to_array.size():
		return false
	var from_slot = from_array[from_slot_index]
	var to_slot = to_array[to_slot_index]
	if not from_slot:
		return false
	if not to_slot:
		to_array[to_slot_index] = from_slot
		from_array[from_slot_index] = null
		inventory_updated.emit()
		return true
	if from_slot.item and to_slot.item and from_slot.item.id == to_slot.item.id:
		var total = from_slot.quantity + to_slot.quantity
		var max_stack = from_slot.item.max_stack
		if total <= max_stack:
			to_slot.quantity = total
			from_array[from_slot_index] = null
		else:
			var space = max_stack - to_slot.quantity
			to_slot.quantity = max_stack
			from_slot.quantity -= space
		inventory_updated.emit()
		return true
	return false

func get_hotbar_slot(index: int) -> ItemStack:
	return hotbar_slots[index] if index < hotbar_slots.size() else null

func get_main_slot(index: int) -> ItemStack:
	return main_slots[index] if index < main_slots.size() else null

func get_item_count(item_id: int) -> int:
	var total = 0
	for slot in hotbar_slots:
		if slot and slot.item and slot.item.id == item_id:
			total += slot.quantity
	for slot in main_slots:
		if slot and slot.item and slot.item.id == item_id:
			total += slot.quantity
	return total

func has_items(requirements: Dictionary) -> bool:
	for item_id in requirements:
		if get_item_count(item_id) < requirements[item_id]:
			return false
	return true

func get_total_radiation_emission() -> float:
	var total = 0.0
	for slot in hotbar_slots:
		if slot and slot.item:
			total += slot.item.radiation_emission * slot.quantity
	for slot in main_slots:
		if slot and slot.item:
			total += slot.item.radiation_emission * slot.quantity
	return total

func consume_items(requirements: Dictionary):
	for item_id in requirements:
		remove_item(item_id, requirements[item_id])
