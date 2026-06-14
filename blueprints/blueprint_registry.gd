extends Node

var blueprints: Dictionary = {}

func _ready():
	register_all_blueprints()

func register_all_blueprints():
	var still_bp = Blueprint.new()
	still_bp.display_name = "Still"
	still_bp.building_scene = preload("res://buildings/still.tscn")
	still_bp.build_costs = {1: 10, 2: 5, 9: 10}  # 10 iron, 5 steel, 10 scrap
	still_bp.preview_color = Color(0, 1, 0, 0.5)
	register_blueprint("still", still_bp)

func register_blueprint(id: String, blueprint: Blueprint):
	blueprints[id] = blueprint

func get_blueprint(id: String) -> Blueprint:
	return blueprints.get(id)
