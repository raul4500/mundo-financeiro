extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "shopping_large",
		"name": "Centro Comercial Mundo Mix",
		"description": "Um grande centro comercial com lojas, servicos e alto potencial de receita.",
		"size": "large",
		"category": "Comercio",
		"purchase_price": 85000.0,
		"base_daily_revenue": 2600.0,
		"base_daily_expenses": 950.0,
		"water_bill": 450.0,
		"electricity_bill": 1100.0,
		"starting_capacity": 100,
		"max_level": 5,
		"revenue_per_capacity": 34.0,
		"upgrade_costs": [60000.0, 120000.0, 220000.0, 400000.0],
		"employee_salary": 1300.0,
		"employee_revenue_bonus": 260.0,
		"employee_capacity_bonus": 10,
		"max_employees": 20,
		"stock_items": [
			{"id": "store_goods", "name": "Produtos para lojas", "price": 1600.0, "units": 10, "consumption": 1, "revenue_bonus": 0.0},
			{"id": "maintenance", "name": "Materiais de manutencao", "price": 900.0, "units": 10, "consumption": 1, "revenue_bonus": 120.0},
			{"id": "advertising", "name": "Publicidade", "price": 1400.0, "units": 10, "consumption": 1, "revenue_bonus": 250.0}
		],
		"equipment_items": [
			{"id": "security", "name": "Sistema de seguranca", "price": 12000.0, "level_required": 1, "revenue_bonus": 500.0, "capacity_bonus": 20, "maintenance_cost": 180.0},
			{"id": "food_court", "name": "Praca de alimentacao", "price": 22000.0, "level_required": 2, "revenue_bonus": 850.0, "capacity_bonus": 35, "maintenance_cost": 280.0},
			{"id": "climate", "name": "Climatizacao central", "price": 30000.0, "level_required": 3, "revenue_bonus": 1100.0, "capacity_bonus": 45, "maintenance_cost": 400.0}
		]
	}
