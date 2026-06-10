extends Node
class_name ItemActions

static var actions = {
	# Только предметы, которые можно использовать
	3: func(player):
		if player.radiation > 0:
			player.radiation = max(player.radiation - 15, 0)
			player.update_health_display()
			return true
		return false,
}
##короче я добавлю типа +0.01 защиты за каждое применение и шейдер чтобы можно было набухаться и стать имбой на короткий срок
			#но рил много надо типа стак или два
static func use(player, item_id: int) -> bool:
	if actions.has(item_id):
		var result = actions[item_id].call(player)
		return result if result != null else true
	# Предмет без действия — использовать нельзя
	return false
