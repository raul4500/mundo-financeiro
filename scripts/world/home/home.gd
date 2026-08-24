extends Control

const UI_THEME = preload("res://themes/font_theme.tres")

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
@onready var hunger_bar: ProgressBar = $"HBoxContainer/Main-panel/VBoxContainer/Status-panel/VBoxContainer/Hunger-container/ProgressBar"
@onready var happiness_bar: ProgressBar = $"HBoxContainer/Main-panel/VBoxContainer/Status-panel/VBoxContainer/Happiness-container/ProgressBar"
@onready var status_label: Label = $"HBoxContainer/Main-panel/VBoxContainer/status-message"
@onready var inventory_scroll: ScrollContainer = $"HBoxContainer/VBoxContainer/Inventory-panel/Inventory-scroll"
@onready var history_scroll: ScrollContainer = $"HBoxContainer/VBoxContainer/History-panel/History-scroll"
@onready var exit_button: Button = $"Exit"
# Node2D vazio na cena que serve de âncora para o sprite do personagem.
@onready var character_holder: Node2D = $"Node2D"

# Containers criados em runtime dentro dos scrolls fixos.
var inventory_list: VBoxContainer
var history_list: VBoxContainer
var character_sprite: AnimatedSprite2D

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Global.play_time = true
	Global.ensure_player_state()
	TimeManager.time_changed.connect(_on_time_changed)
	TimeManager.day_changed.connect(_on_day_changed)
	_build_ui()
	_update_ui()

func _exit_tree() -> void:
	if TimeManager.time_changed.is_connected(_on_time_changed):
		TimeManager.time_changed.disconnect(_on_time_changed)
	if TimeManager.day_changed.is_connected(_on_day_changed):
		TimeManager.day_changed.disconnect(_on_day_changed)

func _on_time_changed(_hour: int, _minute: int) -> void:
	_update_time_label()

func _on_day_changed(_day: int) -> void:
	_update_time_label()

func _update_time_label() -> void:
	if time_label != null:
		time_label.text = "Dia %d | %02d:%02d" % [TimeManager.current_day, TimeManager.current_hour, TimeManager.current_minute]

# =============================================================
# MONTAGEM DOS ELEMENTOS DINÂMICOS
# =============================================================

func _build_ui() -> void:
	_build_action_buttons()
	_build_character()
	inventory_list = _get_or_create_list(inventory_scroll)
	history_list = _get_or_create_list(history_scroll)
	_setup_bar(hunger_bar)
	_setup_bar(happiness_bar)

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

	actions_box.add_child(_make_button("COMER", _on_eat_pressed))
	actions_box.add_child(_make_button("DESCANSAR", _on_rest_pressed))
	actions_box.add_child(_make_button("ASSISTIR TV", _on_tv_pressed))

func _make_button(text: String, callback: Callable) -> Button:
	var button = Button.new()
	button.theme = UI_THEME
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.custom_maximum_size = Vector2(165, 52)
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

	hunger_bar.value = clampf(float(Global.player.get("hunger", 100.0)), 0.0, 100.0)
	happiness_bar.value = clampf(float(Global.player.get("happiness", 100.0)), 0.0, 100.0)

	_render_inventory()
	_render_history()

func _render_inventory() -> void:
	if inventory_list == null:
		return
	_clear_children(inventory_list)

	var items = Global.get_home_inventory_items()
	if items.is_empty():
		inventory_list.add_child(_make_info_label("Você não tem itens no estoque."))
		return

	for item in items:
		var row = HBoxContainer.new()
		row.theme = UI_THEME
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label = Label.new()
		label.theme = UI_THEME
		label.text = "%s x%s" % [item.get("name", "Item"), str(item.get("quantity", 0))]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var meta = Label.new()
		meta.theme = UI_THEME
		meta.text = "Energia %.0f / Felicidade %.0f" % [
			float(item.get("energy", 0.0)),
			float(item.get("happiness", 0.0))
		]

		row.add_child(label)
		row.add_child(meta)
		inventory_list.add_child(row)

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
		var label = _make_info_label("%s - Dia %s / Semana %s" % [
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

func _on_eat_pressed() -> void:
	var result = Global.consume_food()
	status_label.text = result.get("message", "VOCÊ COMEU.")
	_update_ui()

func _on_rest_pressed() -> void:
	var result = Global.apply_home_action("VOCÊ DESCANSOU.", -12.0, 18.0, 1.0)
	status_label.text = result.get("message", "Você descansou.")
	_update_ui()

func _on_tv_pressed() -> void:
	var result = Global.apply_home_action("VOCÊ ASSISTIU TV.", -6.0, 14.0, 1.0)
	status_label.text = result.get("message", "Você assistiu TV.")
	_update_ui()

func _on_exit_pressed() -> void:
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")
