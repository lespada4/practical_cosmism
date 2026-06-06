extends Resource
class_name ItemStack

@export var item: Item
@export var quantity: int = 1

func can_merge_with(other: ItemStack) -> bool:
	return item == other.item and quantity + other.quantity <= item.max_stack

func merge(other: ItemStack) -> bool:
	if not can_merge_with(other):
		return false
	quantity += other.quantity
	return true

func clone() -> ItemStack:
	var copy = ItemStack.new()
	copy.item = item
	copy.quantity = quantity
	return copy
