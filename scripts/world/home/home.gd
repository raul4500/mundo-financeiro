extends Control

const UI_THEME = preload("res://themes/font_theme.tres")
const BankCard = preload("res://scripts/world/bank/bank_card.gd")
# Ícones dos itens vêm do mercado (fonte única do mapa nome -> sprite). O item do
# estoque guarda o nome exibido ("Pão"), a mesma chave de ITEM_ICONS.
const MarketScript = preload("res://scripts/world/market/market.gd")

const ITEM_CARD_HEIGHT := 190
const ITEM_ICON_SIZE := 48

# Mesmo mapa usado por player.gd e raul_minigame.gd: o nome salvo em
# Global.player["name"] aponta para a cena do sprite animado.
const CHARACTER_SCENES = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

# Copiados do sprite de exemplo (raul.tscn) que estava fixo dentro do Node2D:
# o personagem do jogador precisa aparecer exatamente no mesmo lugar e tamanho.
const CHARACTER_POSITION = Vector2(458, 430)
const CHARACTER_SCALE = Vector2(16, 16)
const CHARACTER_ANIMATION = "default"

# Ajuste fino por personagem, somado ao Y de CHARACTER_POSITION. O Phillip
# precisa descer 85 px para ficar alinhado com os outros na casa.
const CHARACTER_Y_OFFSET = {
	"Phillip": 85.0
}

# =============================================================
# NODOS FIXOS DA CENA (scenes/world/places/home.tscn)
# A estrutura é montada no editor. O script apenas a usa como
# ponto de ancoragem e cria os filhos dinâmicos.
# =============================================================
@onready var money_label: Label = $"Money-label"
@onready var time_label: Label = $"Time-label"
@onready var actions_box: VBoxContainer = $"HBoxContainer/Actions/VBoxContainer"
@onready var status_label: Label = $"status-message"
# Abas Comidas/Bebidas (cena home.tscn, nó Food-tabs): o estoque da casa em cards.
@onready var food_grid: GridContainer = $"HBoxContainer/VBoxContainer/Food-tabs/Comidas/ScrollContainer/Food-grid"
@onready var drink_grid: GridContainer = $"HBoxContainer/VBoxContainer/Food-tabs/Bebidas/ScrollContainer/Drink-grid"
@onready var history_scroll: ScrollContainer = $"HBoxContainer/VBoxContainer/History-panel/History-scroll"
@onready var exit_button: Button = $"Exit"
# Node2D vazio na cena que serve de âncora para o sprite do personagem.
@onready var character_holder: Node2D = $"Node2D"

# Containers criados em runtime dentro dos scrolls fixos.
var history_list: VBoxContainer
var character_sprite: AnimatedSprite2D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	if not Global.is_any_tutorial_active():
		Global.play_time = true
	Global.ensure_player_state()
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	_build_ui()
	_update_ui()
	# Explicação das mecânicas da casa, uma vez por partida. Depois do
	# _build_ui() de propósito: as mensagens citam os botões, que precisam já
	# estar na tela atrás do alerta.
	TutorialManager.on_player_entered_home()

func _exit_tree() -> void:
	if TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.disconnect(_on_time_changed)
	if TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.disconnect(_on_day_changed)

func _on_time_changed(_hour: int) -> void:
	_update_time_label()

func _on_day_changed(_day: int) -> void:
	_update_time_label()

func _update_time_label() -> void:
	if time_label != null:
		time_label.text = "Dia %d • %02dh" % [TimeManager.current_day, TimeManager.current_hour]

# =============================================================
# MONTAGEM DOS ELEMENTOS DINÂMICOS
# =============================================================

func _build_ui() -> void:
	_build_action_buttons()
	_build_character()
	history_list = _get_or_create_list(history_scroll)

	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	status_label.text = "TUDO EM ORDEM."

	if not exit_button.pressed.is_connected(_on_exit_pressed):
		exit_button.pressed.connect(_on_exit_pressed)

func _setup_bar(bar: ProgressBar) -> void:
	bar.min_value = 0
	bar.max_value = 100
	# A porcentagem é exibida pela própria barra (a cena já define o font_size).
	bar.show_percentage = true

# O painel Actions vem vazio da cena: os botões de ação são criados aqui.
# O botão de sair NÃO é recriado — a cena já tem o nodo fixo `Exit`.
func _build_action_buttons() -> void:
	_clear_children(actions_box)
	actions_box.add_theme_constant_override("separation", 12)

	var title = Label.new()
	title.theme = UI_THEME
	title.text = "AÇÕES"
	actions_box.add_child(title)

	# Comer e beber não são mais botões: o jogador escolhe o item nas abas
	# Comidas e Bebidas (_render_inventory).
	actions_box.add_child(_make_button("DESCANSAR", _on_rest_pressed))
	actions_box.add_child(_make_button("ASSISTIR TV", _on_tv_pressed))
	actions_box.add_child(_make_button("DORMIR", _on_sleep_pressed))

func _make_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.theme = UI_THEME
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# button.custom_maximum_size = Vector2(165, 52)
	button.pressed.connect(callback)
	return button

# Um ScrollContainer aceita um único filho container para as linhas.
# Reaproveita o container se ele já existir na cena.
func _get_or_create_list(scroll: ScrollContainer) -> VBoxContainer:
	for child in scroll.get_children():
		if child is VBoxContainer:
			return child

	var list = VBoxContainer.new()
	list.name = "List"
	list.theme = UI_THEME
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)
	return list

# remove_child antes do queue_free: sem isso, dois _update_ui() no mesmo frame
# duplicariam as linhas, porque queue_free só libera no fim do frame.
func _clear_children(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

# Instancia o sprite do personagem escolhido pelo jogador dentro do Node2D,
# na mesma posição e escala do sprite de exemplo que existia na cena.
func _build_character() -> void:
	if character_holder == null:
		push_error("home: o Node2D âncora do personagem não existe na cena.")
		return
	_clear_children(character_holder)

	var char_name = str(Global.player.get("name", ""))
	if not CHARACTER_SCENES.has(char_name):
		push_warning("Personagem inválido: '%s'. Usando personagem padrão." % char_name)
		char_name = CHARACTER_SCENES.keys()[0]

	var scene: PackedScene = load(CHARACTER_SCENES[char_name])
	if scene == null:
		push_error("home: não foi possível carregar a cena do personagem '%s'." % char_name)
		return

	character_sprite = scene.instantiate() as AnimatedSprite2D
	if character_sprite == null:
		push_error("home: a cena de '%s' não tem um AnimatedSprite2D na raiz." % char_name)
		return

	character_holder.add_child(character_sprite)
	var sprite_position = CHARACTER_POSITION
	sprite_position.y += float(CHARACTER_Y_OFFSET.get(char_name, 0.0))
	character_sprite.position = sprite_position
	character_sprite.scale = CHARACTER_SCALE
	# As cenas de personagem já têm autoplay = "default", mas deixar explícito
	# evita depender disso e garante o mesmo frame do sprite de exemplo.
	if character_sprite.sprite_frames != null and character_sprite.sprite_frames.has_animation(CHARACTER_ANIMATION):
		character_sprite.play(CHARACTER_ANIMATION)

# =============================================================
# ATUALIZAÇÃO DA INTERFACE
# =============================================================

func _update_ui() -> void:
	Global.ensure_player_state()

	money_label.text = "R$ %.2f" % float(Global.player.get("money", 0.0))
	_update_time_label()
	_render_inventory()
	_render_history()

# Estoque da casa em cards, um grid por aba: itens "food" em Comidas, "drink" em
# Bebidas. Cada card tem ícone, nome, quantidade, o que repõe e o botão de consumir.
func _render_inventory() -> void:
	if food_grid == null or drink_grid == null:
		return
	_clear_children(food_grid)
	_clear_children(drink_grid)

	for item in Global.get_home_inventory_items():
		var category := str(item.get("category", "food"))
		if category == "drink":
			drink_grid.add_child(_make_item_card(item))
		elif category == "food":
			food_grid.add_child(_make_item_card(item))

	if food_grid.get_child_count() == 0:
		food_grid.add_child(BankCard.new_empty_card("Você não tem comidas no estoque."))
	if drink_grid.get_child_count() == 0:
		drink_grid.add_child(BankCard.new_empty_card("Você não tem bebidas no estoque."))

func _make_item_card(item: Dictionary) -> PanelContainer:
	var is_drink := str(item.get("category", "food")) == "drink"
	var item_name := str(item.get("name", "Item"))
	var parts := BankCard.new_card(ITEM_CARD_HEIGHT)
	var box: VBoxContainer = parts["box"]

	box.add_child(_make_item_icon(item_name))
	box.add_child(BankCard.make_label(item_name, 18))
	box.add_child(BankCard.make_label("Estoque: %d" % int(item.get("quantity", 0)), 13))
	box.add_child(BankCard.make_label(_restore_text(item), 14))

	var button := BankCard.make_button("BEBER" if is_drink else "COMER")
	# A chave do estoque é o nome em minúsculas (ver Global.normalize_home_inventory).
	button.pressed.connect(_on_consume_pressed.bind(item_name.to_lower()))
	box.add_child(button)
	return parts["card"]

# Mesmo ícone do card do mercado. Sem sprite para o item, um espaço vazio do
# mesmo tamanho mantém os cards alinhados (o nome já aparece logo abaixo).
func _make_item_icon(item_name: String) -> Control:
	var icon_path: String = MarketScript.ITEM_ICONS.get(item_name, "")
	if icon_path == "" or not ResourceLoader.exists(icon_path):
		var spacer := Control.new()
		spacer.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)
		return spacer
	var icon := TextureRect.new()
	icon.texture = load(icon_path)
	icon.custom_minimum_size = Vector2(ITEM_ICON_SIZE, ITEM_ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return icon

# "Fome +10% / Sede +8%": só o que o item repõe, como no card do mercado.
func _restore_text(item: Dictionary) -> String:
	var parts: Array = []
	if float(item.get("energy", 0.0)) > 0.0:
		parts.append("Fome +%.0f%%" % float(item.get("energy", 0.0)))
	if float(item.get("thirst", 0.0)) > 0.0:
		parts.append("Sede +%.0f%%" % float(item.get("thirst", 0.0)))
	return " / ".join(parts) if not parts.is_empty() else "Sem efeito"

func _render_history() -> void:
	if history_list == null:
		return
	_clear_children(history_list)

	var entries = Global.player.get("home_actions_log", [])
	if entries.is_empty():
		history_list.add_child(_make_info_label("Nenhuma ação registrada."))
		return

	# Mostra apenas as 10 ações mais recentes.
	for entry in entries.slice(max(0, entries.size() - 10)):
		var label = _make_info_label("%s • Dia %s, Semana %s" % [
			str(entry.get("type", "ação")).capitalize(),
			str(entry.get("day", 1)),
			str(entry.get("week", 1))
		])
		history_list.add_child(label)

func _make_info_label(text: String) -> Label:
	var label = Label.new()
	label.theme = UI_THEME
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.text = text
	return label

# =============================================================
# AÇÕES DA CASA (lógica de gameplay inalterada)
# =============================================================

# Comer ou beber o item escolhido no card (a categoria do item decide qual).
func _on_consume_pressed(item_key: String) -> void:
	var result = Global.consume_specific_item(item_key)
	status_label.text = result.get("message", "")
	_update_ui()

func _on_rest_pressed() -> void:
	var result = Global.apply_home_action("VOCÊ DESCANSOU.", -12.0, 18.0, 1.0)
	status_label.text = result.get("message", "Você descansou.")
	_update_ui()

func _on_tv_pressed() -> void:
	var result = Global.apply_home_action("VOCÊ ASSISTIU TV.", -6.0, 14.0, 1.0)
	status_label.text = result.get("message", "Você assistiu TV.")
	_update_ui()

# Unica forma de encerrar o dia por vontade propria. O dia nao acaba mais
# sozinho as 18h: quem nao dormir leva a penalidade da meia-noite
# (ver TimeManager._handle_midnight).
func _on_sleep_pressed() -> void:
	var result = TimeManager.sleep()
	status_label.text = result.get("message", "VOCÊ DORMIU.")
	_update_ui()

func _on_exit_pressed() -> void:
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
