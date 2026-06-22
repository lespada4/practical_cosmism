extends FuelGenerator

func _ready():
	fuel_type = "liquid"
	fuel_items = [12, 14]  # ID жидкого топлива (бензин, солярка)
	fuel_energy = 30.0
	max_fuel = 150.0
