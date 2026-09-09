extends Area2D

# =============================================================
# BASE DAS PORTAS SIMPLES DO MUNDO
#
# Casa, mercado, banco e escritório tinham quatro scripts idênticos, mudando só
# a cena de destino e o nome da variável de "está dentro". A trava de
# progressão (Global.PLACE_UNLOCK_STAGE) precisava entrar em todas elas, então
# virou uma base só: cada porta declara para onde vai e qual chave usa.
#
# A escola (minigame_door) e os empreendimentos (enterprise_door) têm regra
# própria de entrada e ficam de fora desta base.
# =============================================================

# Chave em Global.PLACE_UNLOCK_STAGE. Uma chave desconhecida exige o estágio
# final, então uma porta nova nasce trancada até o fim do tutorial.
var place_id: String = ""
var destination_scene: String = ""

var player_inside := false

# Evita repetir o alerta de porta trancada a cada quadro: is_key_pressed
# continua verdadeiro enquanto a tecla estiver segurada.
var _locked_alert_shown := false

@onready var info_panel: Panel = $"Info-panel"
@onready var info_hint: Label = $"Info-panel/Margin/VBoxContainer/Hint"

func _process(_delta: float) -> void:
	if Global.gameplay_locked or not player_inside:
		return
	if not Input.is_key_pressed(KEY_ENTER):
		return
	if not Global.is_place_unlocked(place_id):
		if not _locked_alert_shown:
			_locked_alert_shown = true
			AlertManager.alert(Global.place_lock_reason(place_id))
		return
	TransitionManager.change_scene(destination_scene)

# O painel da porta explica por que ela não abre, em vez de deixar o jogador
# apertando ENTER sem retorno. Mesma ideia do painel da escola.
func _update_info_hint() -> void:
	if info_hint == null:
		return
	if Global.is_place_unlocked(place_id):
		info_hint.text = "Pressione ENTER para entrar"
	else:
		info_hint.text = Global.place_lock_reason(place_id)

func _on_body_shape_entered(_body_rid: RID, _body: CharacterBody2D, _body_shape_index: int, _local_shape_index: int) -> void:
	_update_info_hint()
	info_panel.show()
	player_inside = true

func _on_body_shape_exited(_body_rid: RID, _body: CharacterBody2D, _body_shape_index: int, _local_shape_index: int) -> void:
	info_panel.hide()
	player_inside = false
	_locked_alert_shown = false
