extends Node
class_name ItemActions

enum ItemType { CONSUMABLE, TOOL, EQUIPMENT }

static var items = {
	3: {"method": "use_moonshine", "type": ItemType.CONSUMABLE},
	5: {"method": "use_antirad", "type": ItemType.CONSUMABLE},
	# 6: {"method": "use_hammer", "type": ItemType.TOOL},
}

static func use(player, item_id: int) -> bool:
	if items.has(item_id):
		var item = items[item_id]
		var method = item["method"]
		
		if player.has_method(method):
			player.call(method)
			
			# Если расходник — удаляем
			if item["type"] == ItemType.CONSUMABLE:
				player.inventory.remove_item(item_id, 1)
			
			return true
	return false
