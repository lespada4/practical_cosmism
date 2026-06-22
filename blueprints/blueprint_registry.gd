extends Node

var blueprints: Dictionary = {}

func _ready():
	register_all_blueprints()

func register_all_blueprints():
	var still_bp = Blueprint.new()
	still_bp.display_name = "Still"
	still_bp.building_scene = preload("res://buildings/still.tscn")
	still_bp.build_costs = {1: 10, 2: 5, 9: 10}
	register_blueprint("still", still_bp)
	
	var generator_bp = Blueprint.new()
	generator_bp.display_name = "Generator"
	generator_bp.building_scene = preload("res://buildings/gasoline_generator.tscn")
	generator_bp.build_costs = {9: 1}
	register_blueprint("generator", generator_bp)

	var cable_pole_bp = Blueprint.new()
	cable_pole_bp.display_name = "Cable Pole"
	cable_pole_bp.building_scene = preload("res://buildings/cable_pole.tscn")
	cable_pole_bp.build_costs = {9: 1}
	register_blueprint("cable_pole", cable_pole_bp)

	var derad_bp = Blueprint.new()
	derad_bp.display_name = "DeRad"
	derad_bp.building_scene = preload("res://buildings/de_rad_1.tscn")
	derad_bp.build_costs = {9: 1}
	register_blueprint("derad", derad_bp)

func get_blueprint_id_by_building(building: Node) -> String:
	for id in blueprints:
		var bp = blueprints[id]
		if bp.building_scene and bp.building_scene.can_instantiate():
			var instance = bp.building_scene.instantiate()
			var result = instance.get_script() == building.get_script()
			instance.queue_free()
			if result:
				return id
	return ""

func register_blueprint(id: String, blueprint: Blueprint):
	blueprints[id] = blueprint

func get_blueprint(id: String) -> Blueprint:
	return blueprints.get(id)
