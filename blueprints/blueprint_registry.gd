extends Node

var blueprints: Dictionary = {}

func _ready():
	register_all_blueprints()

func register_all_blueprints():
	var still_bp = Blueprint.new()
	still_bp.display_name = "Still"
	still_bp.building_scene = preload("res://buildings/still.tscn")
	still_bp.build_costs = {1: 10, 2: 5, 9: 10}  # 10 iron, 5 steel, 10 scrap
	register_blueprint("still", still_bp)
	
	# Генератор (тестовый крафт)
	var generator_bp = Blueprint.new()
	generator_bp.display_name = "Generator"
	generator_bp.building_scene = preload("res://buildings/hard_fuel_generator.tscn")
	generator_bp.build_costs = {9: 1}  # 1 scrap для теста
	#generator_bp.preview_color = Color(0, 1, 0, 0.5)
	register_blueprint("generator", generator_bp)

	var cable_pole_bp = Blueprint.new()
	cable_pole_bp.display_name = "Cable Pole"
	cable_pole_bp.building_scene = preload("res://buildings/cable_pole.tscn")
	cable_pole_bp.build_costs = {9: 1}  # 1 scrap
	cable_pole_bp.preview_color = Color(0, 1, 0, 0.5)
	register_blueprint("cable_pole", cable_pole_bp)


func register_blueprint(id: String, blueprint: Blueprint):
	blueprints[id] = blueprint

func get_blueprint(id: String) -> Blueprint:
	return blueprints.get(id)
