extends CanvasLayer

@onready var panel = $Panel
@onready var titulo = $Panel/Titulo
@onready var descricao = $Panel/Descricao
@onready var botao = $Panel/Button

func _ready():
	panel.visible = false
	EventsManager.connect("evento_ocorreu", Callable(self, "_on_evento"))


func _on_evento(evento):
	panel.visible = true
	titulo.text = evento.get("titulo", "Evento")
	descricao.text = evento.get("descricao", "")


func _on_button_pressed() -> void:
	panel.visible = false
