extends Node

# =============================
# 📦 DADOS DAS MISSÕES (3 POR SEMANA)
# =============================
var missions_data: Dictionary = {
	1: [
		{
			"id": "economizar_100",
			"description": "Economize R$100",
			"type": "money_min",
			"value": 100
		},
		{
			"id": "sem_gastar",
			"description": "Não gaste dinheiro por 1 dia",
			"type": "no_spend_day"
		},
		{
			"id": "registrar_gastos",
			"description": "Registre seus gastos",
			"type": "log_expense"
		}
	],

	2: [
		{
			"id": "poupanca",
			"description": "Guarde dinheiro na poupança",
			"type": "invest"
		},
		{
			"id": "economizar_300",
			"description": "Economize R$300",
			"type": "money_min",
			"value": 300
		},
		{
			"id": "evitar_impulso",
			"description": "Evite compras impulsivas",
			"type": "no_impulse"
		}
	],

	3: [
		{
			"id": "investir_fundo",
			"description": "Invista em um fundo",
			"type": "invest"
		},
		{
			"id": "analise_gastos",
			"description": "Analise seus gastos da semana",
			"type": "analyze"
		},
		{
			"id": "economizar_500",
			"description": "Economize R$500",
			"type": "money_min",
			"value": 500
		}
	],

	4: [
		{
			"id": "investir_acoes",
			"description": "Invista em ações",
			"type": "invest"
		},
		{
			"id": "diversificar",
			"description": "Diversifique investimentos",
			"type": "diversify"
		},
		{
			"id": "lucro_200",
			"description": "Ganhe R$200 com investimentos",
			"type": "profit",
			"value": 200
		}
	],

	5: [
		{
			"id": "carteira",
			"description": "Monte uma carteira completa",
			"type": "portfolio"
		},
		{
			"id": "alcancar_2000",
			"description": "Alcance R$2000",
			"type": "money_min",
			"value": 2000
		},
		{
			"id": "saldo_positivo",
			"description": "Mantenha saldo positivo por 7 dias",
			"type": "positive_days",
			"value": 7
		}
	]
}


# =============================
# 📥 PEGAR MISSÕES
# =============================
func get_missions(week: int) -> Array:
	return missions_data.get(week, [])


# =============================
# ✔ VERIFICAR MISSÕES
# =============================
func verify_missions(week: int) -> bool:
	var missions = get_missions(week)
	
	for mission in missions:
		if not _check_mission(mission):
			print("❌ Falhou na missão:", mission["description"])
			_game_over()
			return false
	
	print("✅ Todas as missões concluídas!")
	return true


# =============================
# 🧠 VERIFICAÇÃO
# =============================
func _check_mission(mission: Dictionary) -> bool:
	match mission["type"]:
		
		"money_min":
			return Global.player["money"] >= mission.get("value", 0)
		
		"no_spend_day":
			return true
			#return ExpenseManager.get_total_day(TimeManager.current_day) == 0
		
		"log_expense":
			return true
			#return ExpenseManager.purchases.size() > 0
		
		"no_impulse":
			return true
			#return ExpenseManager.get_superfluous_ratio() < 0.3
		
		"invest":
			return true
		
		"analyze":
			return true
		
		"diversify":
			return true
		
		"profit":
			return Global.player["saldo"] >= mission.get("value", 0)
		
		"portfolio":
			return true
		
		"positive_days":
			return true
		
		_:
			print("⚠ Tipo não implementado:", mission["type"])
			return true


# =============================
# 💀 GAME OVER
# =============================
func _game_over():
	print("💀 Game Over!")
	var name = Global.player.get("name", "Player")
	var money = Global.player.get("salary", 0)
	Global.new_game(name, money)
