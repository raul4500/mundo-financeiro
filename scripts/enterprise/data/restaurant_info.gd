extends RefCounted

static func get_data() -> Dictionary:
	return {
		"id": "restaurant_small",
		"name": "Restaurante Sabor da Praca",
		"description": "Um restaurante pequeno para iniciar sua jornada empreendedora.",
		"size": "small",
		"category": "Alimentacao",
		"purchase_price": 1500.0,
		"base_daily_revenue": 70.0,
		"base_daily_expenses": 25.0,
		"water_bill": 20.0,
		"electricity_bill": 30.0,
		"starting_capacity": 10,
		"max_level": 5,
		"stock_items": [
			{"id": "ingredients", "name": "Ingredientes basicos", "price": 80.0, "units": 5, "consumption": 1, "revenue_bonus": 0.0},
			{"id": "drinks", "name": "Bebidas", "price": 45.0, "units": 5, "consumption": 1, "revenue_bonus": 8.0},
			{"id": "cleaning", "name": "Itens de limpeza", "price": 35.0, "units": 5, "consumption": 1, "revenue_bonus": 0.0}
		],
		"equipment_items": [
			{"id": "stove", "name": "Fogao industrial", "price": 350.0, "level_required": 1, "revenue_bonus": 18.0, "capacity_bonus": 2, "maintenance_cost": 8.0},
			{"id": "fridge", "name": "Geladeira maior", "price": 600.0, "level_required": 2, "revenue_bonus": 28.0, "capacity_bonus": 4, "maintenance_cost": 12.0},
			{"id": "tables", "name": "Mesas confortaveis", "price": 900.0, "level_required": 3, "revenue_bonus": 42.0, "capacity_bonus": 8, "maintenance_cost": 15.0}
		]
	}
