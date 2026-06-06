extends Area3D

var item_id: int = 0
var amount: int = 1
var can_collect: bool = false

@onready var sprite: Sprite3D = $Sprite3D

func setup(item_resource: Item, item_amount: int):
	item_id = item_resource.id
	amount = item_amount
	
	if sprite and item_resource.icon:
		sprite.texture = item_resource.icon
	
	body_entered.connect(_on_body_entered)

func _ready():
	await get_tree().create_timer(1.0).timeout
	can_collect = true
	check_player_inside()

func check_player_inside():
	var bodies = get_overlapping_bodies()
	for body in bodies:
		if body.name == "Player" and can_collect:
			body.collect_item(item_id, amount)
			queue_free()
			break

func _on_body_entered(body):
	if body.name == "Player" and can_collect:
		body.collect_item(item_id, amount)
		queue_free()
