extends Area2D

@export var enterprise_id: String = "restaurant_small"
@export var destination_scene: String = "res://scenes/world/places/restaurant.tscn"

var player_inside := false
var dialog_locked := false
var purchase_layer: CanvasLayer
var purchase_panel: Panel
var purchase_label: Label
var buy_button: Button
var exit_button: Button

# Painel de informação da porta: existe na cena, escondido, e só aparece
# enquanto o jogador estiver dentro da Area2D.
# Resolvido dentro de _ready() e não com @onready porque este script é a base
# de restaurant_door/arcade_door/shopping_door, que sobrescrevem _ready().
var info_panel: Panel
var info_hint: Label

func _ready() -> void:
	info_panel = get_node_or_null("Info-panel")
	if info_panel != null:
		info_hint = info_panel.get_node_or_null("Margin/VBoxContainer/Hint")
	_build_purchase_ui()

func _process(_delta: float) -> void:
	if Global.gameplay_locked or not player_inside:
		return
	if Input.is_key_pressed(KEY_ENTER):
		_open_or_enter()

func _open_or_enter() -> void:
	if EnterpriseManager.is_owned(enterprise_id):
		get_tree().change_scene_to_file(destination_scene)
		return
	_show_purchase_dialog()

# =============================
# 🪧 PAINEL DE INFORMAÇÃO DA PORTA
# =============================
func _show_info_panel() -> void:
	if info_panel == null:
		return
	_update_info_hint()
	info_panel.show()

func _hide_info_panel() -> void:
	if info_panel != null:
		info_panel.hide()

func _update_info_hint() -> void:
	if info_hint == null:
		return
	# A tecla é sempre ENTER, mas o resultado muda: quem já é dono entra no
	# negócio, quem não é vê primeiro a proposta de compra.
	if EnterpriseManager.is_owned(enterprise_id):
		info_hint.text = "Pressione ENTER para entrar"
	else:
		info_hint.text = "Pressione ENTER para ver a proposta"

func _build_purchase_ui() -> void:
	purchase_layer = CanvasLayer.new()
	purchase_layer.layer = 90
	purchase_layer.name = "EnterprisePurchaseLayer"
	add_child(purchase_layer)

	var blocker = ColorRect.new()
	blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	blocker.color = Color(0, 0, 0, 0.45)
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.visible = false
	blocker.name = "Blocker"
	purchase_layer.add_child(blocker)

	purchase_panel = Panel.new()
	purchase_panel.set_anchors_preset(Control.PRESET_CENTER)
	purchase_panel.position = Vector2(-280, -150)
	purchase_panel.size = Vector2(560, 300)
	purchase_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	purchase_panel.visible = false
	purchase_layer.add_child(purchase_panel)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	purchase_panel.add_child(margin)

	var box = VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	purchase_label = Label.new()
	purchase_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	purchase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	purchase_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(purchase_label)

	var buttons = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	box.add_child(buttons)

	buy_button = Button.new()
	buy_button.text = "Comprar"
	buy_button.custom_minimum_size = Vector2(150, 44)
	buy_button.pressed.connect(_on_buy_pressed)
	buttons.add_child(buy_button)

	exit_button = Button.new()
	exit_button.text = "Sair"
	exit_button.custom_minimum_size = Vector2(150, 44)
	exit_button.pressed.connect(_on_exit_pressed)
	buttons.add_child(exit_button)

	purchase_layer.get_node("Blocker").gui_input.connect(_on_blocker_input)

func _show_purchase_dialog() -> void:
	var info = EnterpriseManager.get_enterprise_info(enterprise_id)
	if info.is_empty():
		return
	var price = float(info.get("purchase_price", 0.0))
	var money = float(Global.player.get("money", 0.0))
	purchase_label.text = "%s\n\n%s\n\nPreço: R$ %.2f\nSeu dinheiro: R$ %.2f" % [
		info.get("name", "Empreendimento"),
		info.get("description", "Este prédio está disponível para compra."),
		price,
		money
	]
	buy_button.disabled = money < price
	buy_button.tooltip_text = "" if money >= price else "Dinheiro insuficiente. Faltam R$ %.2f." % (price - money)
	# O diálogo de compra ocupa a tela inteira, então o painel da porta sai de cena.
	_hide_info_panel()
	purchase_layer.get_node("Blocker").visible = true
	purchase_panel.visible = true
	if not dialog_locked:
		dialog_locked = true
		Global.play_time = false
		Global.lock_gameplay()

func _on_buy_pressed() -> void:
	var result = EnterpriseManager.buy_enterprise(enterprise_id)
	if not result.get("success", false):
		AlertManager.alert(str(result.get("message", "Não foi possível comprar o empreendimento.")))
		return
	_close_purchase_dialog()
	get_tree().change_scene_to_file(destination_scene)

func _on_exit_pressed() -> void:
	_close_purchase_dialog()

func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close_purchase_dialog()

func _close_purchase_dialog() -> void:
	purchase_layer.get_node("Blocker").visible = false
	purchase_panel.visible = false
	if dialog_locked:
		dialog_locked = false
		Global.unlock_gameplay()
	# Só volta a correr o tempo se nada mais estiver travando o gameplay.
	if not Global.gameplay_locked:
		Global.play_time = true
	# Se o jogador continua na porta, o painel de informação volta a aparecer.
	if player_inside:
		_show_info_panel()

func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body is CharacterBody2D:
		player_inside = true
		_show_info_panel()

func _on_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if body is CharacterBody2D:
		player_inside = false
		_hide_info_panel()
		if purchase_panel != null and purchase_panel.visible:
			_close_purchase_dialog()
