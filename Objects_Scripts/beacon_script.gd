extends StaticBody3D
#class_name Beacon
#
#@export var connection_point: Marker3D
#@export var required_items: Dictionary = {1: 10, 2: 5, 12: 3}  # 10 iron, 5 steel, 3 rad parts
#@export var is_active: bool = false
#
#


func _ready() -> void:
	pass
#func _find_selected_pole_in_range() -> CablePole:
	#var search_radius = 8.0
	#for pole in get_tree().get_nodes_in_group("cable_poles"):
		#if pole.is_selected and global_position.distance_to(pole.global_position) <= search_radius:
			#return pole
	#return null
#
#func interact(player):
	#var selected_pole = _find_selected_pole_in_range()
	#if selected_pole:
		#selected_pole.connect_to_device(self)
		#return
	#
	#if is_active:
		#return
	#
	#if not _has_required_items(player.inventory):
		## TODO: сообщение "Не хватает ресурсов"
		#print("Not enough resources!")
		#return
	#
	#_activate(player)
#
#func _has_required_items(inventory) -> bool:
	#for item_id in required_items:
		#if inventory.get_item_count(item_id) < required_items[item_id]:
			#return false
	#return true
#
#func _activate(player):
	## Потребляем ресурсы
	#for item_id in required_items:
		#player.inventory.remove_item(item_id, required_items[item_id])
	#
	#is_active = true
	#
	## Можно добавить звук, анимацию
	#
	## Финальное событие
	#await get_tree().create_timer(1.0).timeout
	#player.show_demo_complete()
#
#func _create_indicator_material(color: Color) -> StandardMaterial3D:
	#var mat = StandardMaterial3D.new()
	#mat.albedo_color = color
	#mat.emission_enabled = true
	#mat.emission = color
	#return mat
#
#func get_connection_point() -> Marker3D:
	#return connection_point
#
#func deconstruct(_player):
	#var poles = get_tree().get_nodes_in_group("cable_poles")
	#for pole in poles:
		#if pole.has_method("_remove_device_wire"):
			#pole.call("_remove_device_wire", self)
	#
	## Маяк не возвращает ресурсы при демонтаже
	#queue_free()
