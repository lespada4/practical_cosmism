extends Node
class_name Inventory

signal inventory_updated

var hotbar_slots: Array[ItemStack] = []  # 9 слотов
var main_slots: Array[ItemStack] = []    # 20-28 слотов

var hotbar_size: int = 9
var main_size: int = 20

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
	# Сначала ищем в хотбаре
	if try_add_to_slots(hotbar_slots, item_id, amount):
		return true
	# Потом в основном инвентаре
	if try_add_to_slots(main_slots, item_id, amount):
		return true
	return false

func try_add_to_slots(slots_array: Array, item_id: int, amount: int) -> bool:
	var item = ItemRegistry.get_item(item_id)
	if not item:
		return false
	
	var remaining = amount
	
	# Поиск существующих стаков
	for i in range(slots_array.size()):
		var slot = slots_array[i]
		if slot and slot.item.id == item_id and slot.quantity < item.max_stack:
			var space = item.max_stack - slot.quantity
			var to_add = min(space, remaining)
			slot.quantity += to_add
			remaining -= to_add
			inventory_updated.emit()
			if remaining == 0:
				return true
	
	# Поиск пустых слотов
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
	var remaining = amount
	
	# Сначала из хотбара
	if remove_from_slots(hotbar_slots, item_id, remaining, remaining):
		return true
	# Потом из основного
	if remove_from_slots(main_slots, item_id, remaining, remaining):
		return true
	return false

func remove_from_slots(slots_array: Array, item_id: int, amount: int, _remaining_ref) -> bool:
	var remaining = amount
	for i in range(slots_array.size() - 1, -1, -1):
		var slot = slots_array[i]
		if slot and slot.item.id == item_id:
			if slot.quantity > remaining:
				slot.quantity -= remaining
				remaining = 0
				inventory_updated.emit()
				return true
			else:
				remaining -= slot.quantity
				slots_array[i] = null
	
	return remaining == 0

func get_item_count(item_id: int) -> int:
	var total = 0
	for slot in hotbar_slots:
		if slot and slot.item.id == item_id:
			total += slot.quantity
	for slot in main_slots:
		if slot and slot.item.id == item_id:
			total += slot.quantity
	return total

func swap_slots(from_hotbar: bool, from_index: int, to_hotbar: bool, to_index: int):
	var from_array = hotbar_slots if from_hotbar else main_slots
	var to_array = hotbar_slots if to_hotbar else main_slots
	
	var temp = from_array[from_index]
	from_array[from_index] = to_array[to_index]
	to_array[to_index] = temp
	
	inventory_updated.emit()

func get_hotbar_slot(index: int) -> ItemStack:
	if index < hotbar_slots.size():
		return hotbar_slots[index]
	return null

func get_main_slot(index: int) -> ItemStack:
	if index < main_slots.size():
		return main_slots[index]
	return null
