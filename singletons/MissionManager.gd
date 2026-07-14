extends Node

var missions_data = {
	1: [
		"Economize R$100",
		"Não gaste dinheiro por 1 dia",
		"Registre seus gastos"
	],
	2: [
		"Guarde dinheiro na poupança",
		"Economize R$300",
		"Evite compras impulsivas"
	],
	3: [
		"Invista em um fundo",
		"Analise seus gastos da semana",
		"Economize R$500"
	],
	4: [
		"Invista em ações",
		"Diversifique investimentos",
		"Ganhe R$200 com investimentos"
	],
	5: [
		"Monte uma carteira completa",
		"Alcance R$2000",
		"Mantenha saldo positivo por 7 dias"
	]
}

func verificate_missons(week):
	if week == 1:
		if Global.player["money"] < 100.00:
			print("não economizou R$100,00")
			Global.new_game(Global.player["name"], Global.player["salary"])
			return false
	return true
			
			
			
			
