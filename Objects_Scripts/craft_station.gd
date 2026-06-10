extends StaticBody3D

@export var station_type: String = "still"

func interact(player):
	player.crafting_ui.open(station_type)
