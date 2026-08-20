extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "arcade_medium",
		"name": "Fliperama Neon",
		"description": "Um espaco de lazer com maquinas e experiencias para varios clientes.",
		"size": "medium",
		"category": "Lazer",
		"purchase_price": 12000.0,
		"base_daily_revenue": 420.0,
		"base_daily_expenses": 150.0,
		"water_bill": 80.0,
		"electricity_bill": 220.0,
		"starting_capacity": 25,
		"max_level": 5,
		"revenue_per_capacity": 22.0,
		"upgrade_costs": [9000.0, 18000.0, 32000.0, 55000.0],
		"employee_salary": 420.0,
		"employee_revenue_bonus": 85.0,
		"employee_capacity_bonus": 6,
		"max_employees": 8,
		"stock_items": [
			{"id": "credits", "name": "Fichas e creditos", "price": 250.0, "units": 10, "consumption": 1, "revenue_bonus": 0.0},
			{"id": "snacks", "name": "Lanches", "price": 180.0, "units": 10, "consumption": 1, "revenue_bonus": 35.0},
			{"id": "cleaning", "name": "Produtos de limpeza", "price": 120.0, "units": 10, "consumption": 1, "revenue_bonus": 0.0}
		],
		"equipment_items": [
			{"id": "arcade_machine", "name": "Maquina de arcade", "price": 1800.0, "level_required": 1, "revenue_bonus": 100.0, "capacity_bonus": 5, "maintenance_cost": 35.0},
			{"id": "dance_machine", "name": "Maquina de danca", "price": 3200.0, "level_required": 2, "revenue_bonus": 180.0, "capacity_bonus": 8, "maintenance_cost": 55.0},
			{"id": "sound_system", "name": "Sistema de som", "price": 4500.0, "level_required": 3, "revenue_bonus": 260.0, "capacity_bonus": 12, "maintenance_cost": 70.0}
		]
	}
