extends Area2D

var dentro = false
# Painel de informação da porta: fica escondido na cena e só aparece
# enquanto o jogador estiver dentro da Area2D.
@onready var info_panel: Panel = $"Info-panel"
@onready var info_hint: Label = $"Info-panel/Margin/VBoxContainer/Hint"

# Evita repetir o alerta de porta trancada a cada frame: _process roda com
# is_key_pressed, que continua verdadeiro enquanto a tecla estiver segurada.
var locked_alert_shown = false

func _process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	if Input.is_key_pressed(KEY_ENTER) and dentro == true:
		if not MinigameManager.can_play():
			if not locked_alert_shown:
				locked_alert_shown = true
				AlertManager.alert(MinigameManager.lock_reason())
			return
		# Tutorial: ao entrar na escola e após a explicação, o jogador pode avançar.
		TutorialManager.on_player_entered_school()
		TransitionManager.change_scene("res://scenes/minigame/minigame.tscn")

func _update_info_hint() -> void:
	if info_hint == null:
		return
	# A escola pode estar fechada por cooldown; o painel diz o porquê em vez
	# de deixar o jogador apertando ENTER sem entender o que houve.
	if MinigameManager.can_play():
		info_hint.text = "Pressione ENTER para entrar"
	else:
		info_hint.text = MinigameManager.lock_reason()

func _on_body_shape_entered(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	_update_info_hint()
	info_panel.show()
	dentro = true

func _on_body_shape_exited(body_rid: RID, body: CharacterBody2D, body_shape_index: int, local_shape_index: int) -> void:
	info_panel.hide()
	dentro = false
	locked_alert_shown = false
