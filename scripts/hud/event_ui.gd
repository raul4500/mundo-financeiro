extends CanvasLayer

@onready var panel = $Panel
@onready var titulo = $Panel/Titulo
@onready var descricao = $Panel/Descricao
@onready var botao = $Panel/Button

var choice_buttons: Array = []
# Guardado porque a pendência só é criada quando o jogador clica numa escolha,
# e aí precisamos do evento que originou os botões.
var current_evento: Dictionary = {}

func _ready():
	panel.visible = false
	EventsManager.connect("evento_ocorreu", Callable(self, "_on_evento"))


func _on_evento(evento):
	current_evento = evento
	panel.visible = true
	titulo.text = evento.get("titulo", "Evento")
	descricao.text = evento.get("descricao", "")

	_clear_choice_buttons()

	if evento.has("escolhas"):
		botao.visible = false
		_build_choice_buttons(evento["escolhas"])
	else:
		botao.visible = true


func _build_choice_buttons(escolhas: Array) -> void:
	var y_offset = botao.position.y
	for escolha in escolhas:
		var choice_button = Button.new()
		choice_button.text = escolha.get("descricao", "Escolher")
		choice_button.position = Vector2(botao.position.x, y_offset)
		choice_button.size = botao.size
		choice_button.pressed.connect(_on_choice_pressed.bind(escolha))
		panel.add_child(choice_button)
		choice_buttons.append(choice_button)
		y_offset -= choice_button.size.y + 8


func _on_choice_pressed(escolha: Dictionary) -> void:
	# Refatorado: a escolha não debita/credita na hora. Ela cria uma pendência
	# que o jogador resolve no banco, igual aos eventos automáticos. Opções de
	# impacto zero ("Não comprar") não geram nada.
	var evento = current_evento.duplicate(true)
	evento["titulo"] = "%s — %s" % [
		str(current_evento.get("titulo", "Evento")),
		str(escolha.get("descricao", ""))
	]
	EventsManager.create_pending_event(evento, escolha.get("impacto", {}))
	panel.visible = false
	_clear_choice_buttons()


func _clear_choice_buttons() -> void:
	for b in choice_buttons:
		if is_instance_valid(b):
			b.queue_free()
	choice_buttons.clear()


func _on_button_pressed() -> void:
	panel.visible = false
