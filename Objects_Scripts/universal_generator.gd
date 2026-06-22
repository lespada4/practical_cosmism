extends FuelGenerator

func _ready():
	fuel_type = "universal"
	fuel_items = [10, 13, 14]  # уголь + жидкое топливо
	fuel_energy = 20.0
	max_fuel = 200.0
