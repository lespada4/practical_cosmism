extends Node
class_name ItemActions

static var actions = {
	1: func(_player): 
		print("Iron has no use yet"),
	
	2: func(_player):
		print("Steel has no use yet"),
	
	3: func(player):
		if player.radiation > 0:
			player.radiation = max(player.radiation - 15, 0)
			player.update_health_display()
			return true
		return false,
}

static func use(player, item_id: int) -> bool:
	if actions.has(item_id):
		var result = actions[item_id].call(player)
		return result if result != null else true
	return false
