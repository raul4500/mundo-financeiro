extends Node

signal evento_ocorreu(evento)

#var eventos: Array = UnexpectedEvents.unexpected_events["eventos"]

var eventos: Array = [
	{
	  "id": "quebra_carro",
	  "titulo": "Problema no carro",
	  "descricao": "Seu carro quebrou e precisa de conserto urgente.",
	  "tipo": "negativo",
	  "categoria": "emergencia",
	  "impacto": {
		"dinheiro": -500
	  },
	  "probabilidade": 0.2
	},
	{
	  "id": "promocao_trabalho",
	  "titulo": "Promoção no trabalho",
	  "descricao": "Você foi promovido e recebeu um bônus!",
	  "tipo": "positivo",
	  "categoria": "renda",
	  "impacto": {
		"dinheiro": 800
	  },
	  "probabilidade": 0.15
	},
	{
	  "id": "gasto_saude",
	  "titulo": "Despesa médica",
	  "descricao": "Você teve um problema de saúde inesperado.",
	  "tipo": "negativo",
	  "categoria": "emergencia",
	  "impacto": {
		"dinheiro": -300
	  },
	  "probabilidade": 0.2
	},
	{
	  "id": "freelance",
	  "titulo": "Trabalho extra",
	  "descricao": "Você conseguiu um trabalho freelance no fim de semana.",
	  "tipo": "positivo",
	  "categoria": "renda_extra",
	  "impacto": {
		"dinheiro": 400
	  },
	  "probabilidade": 0.25
	},
	{
	  "id": "tentacao_compra",
	  "titulo": "Promoção imperdível",
	  "descricao": "Você encontrou uma promoção tentadora no shopping.",
	  "tipo": "negativo",
	  "categoria": "emergencia",
	  "impacto": {
		"dinheiro": -300
	  },
	  "probabilidade": 0.2
	}
  ]

# Caminho do JSON
#const EVENTOS_PATH = "res://data/configs/eventos_inesperados.json"
#func load_eventos():
#	var file = FileAccess.open(EVENTOS_PATH, FileAccess.READ)
#	if file == null:
#		push_error("Erro ao abrir arquivo de eventos")
#		return
#	
#	var content = file.get_as_text()
#	var data = JSON.parse_string(content)
#	
#	if data == null:
#		push_error("Erro ao parsear JSON de eventos")
#		return
#	
#	eventos = data["eventos"]
#	print("Eventos carregados: ", eventos.size())


# =============================
# 🎲 SORTEAR EVENTO
# =============================
func sortear_evento():
	for evento in eventos:
		if randf() < evento.get("probabilidade", 0.1):
			return evento
	return null


# =============================
# ⚡ DISPARAR EVENTO
# =============================
func trigger_evento():
	var evento = eventos[0]
	evento = sortear_evento()
	
	if evento == null:
		print("Nenhum evento ocorreu")
		return
	
	print("Evento: ", evento["titulo"])
	emit_signal("evento_ocorreu", evento)
	
	# Se tiver escolhas → precisa de UI
	if evento.has("escolhas"):
		return evento  # UI decide o que fazer
	
	# Evento automático
	aplicar_impacto(evento["impacto"])
	
	return evento


# =============================
# 💥 APLICAR IMPACTO
# =============================
func aplicar_impacto(impacto: Dictionary):
	
	if impacto.has("dinheiro"):
		Global.player["money"] += impacto["dinheiro"]
	
	print("Impacto aplicado: ", impacto)
	print("Saldo atual: ", Global.player["money"])



var save_timer := 0.0
var save_interval := 10.0 # segundos

func _process(delta):
	save_timer += delta
	if save_timer >= save_interval:
		print("evento sorteado")
		var evento = trigger_evento()
		save_timer = 0
