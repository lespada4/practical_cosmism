extends Node
class_name ItemActions

enum ItemType { CONSUMABLE, TOOL, EQUIPMENT }

static var items = {
	3: {"method": "use_moonshine", "type": ItemType.CONSUMABLE},
	8: {"method": "use_cockroach", "type": ItemType.CONSUMABLE},
	11: {"method": "use_crowbar", "type": ItemType.TOOL},
}

static func use(player, item_id: int, target: Node = null) -> bool:
	if items.has(item_id):
		var item = items[item_id]
		var method = item["method"]
		
		if player.has_method(method):
			# Для инструментов проверяем цель
			if item["type"] == ItemType.TOOL:
				if not target:
					return false  # Нет цели — не используем
				player.call(method, target)
			else:
				player.call(method)
		
		if item["type"] == ItemType.CONSUMABLE:
			player.inventory.remove_item(item_id, 1)
		
		return true
	return false
