extends Area2D

# Ponto de entrada do minigame de moedas do parque. Mesmo padrão das portas
# (scripts/world/doors/place_door.gd): jogador entra na área e aperta ENTER,
# mas em vez de trocar de cena inicia a sessão no próprio mundo aberto.

const ParkMinigameSession = preload("res://scripts/park/park_minigame_session.gd")

# Área real do parque, desenhada no editor: Node2D "Park" > Area2D
# "Park-zone" > CollisionPolygon2D. As moedas só nascem dentro dela.
const PARK_ZONE_PATH := "Park/Park-zone/CollisionPolygon2D"

var player_inside := false
var _locked_alert_shown := false

@onready var info_panel: Panel = $"Info-panel"
@onready var info_hint: Label = $"Info-panel/Margin/VBoxContainer/Hint"

func _process(_delta: float) -> void:
	if Global.gameplay_locked or not player_inside:
		return
	if not Input.is_key_pressed(KEY_ENTER):
		return
	if not ParkMinigameManager.can_play():
		if not _locked_alert_shown:
			_locked_alert_shown = true
			AlertManager.alert(ParkMinigameManager.lock_reason())
		return
	_start_minigame()

func _start_minigame() -> void:
	var spawn_polygon := _get_spawn_polygon()
	if spawn_polygon.is_empty():
		AlertManager.alert("A área do parque não foi encontrada. Avise o desenvolvedor.")
		return
	var session := ParkMinigameSession.new()
	get_tree().current_scene.add_child(session)
	session.start(get_tree().current_scene, spawn_polygon)

# Converte o CollisionPolygon2D desenhado no editor (pontos locais) para
# coordenadas de mundo, que é o espaço em que as moedas são posicionadas.
func _get_spawn_polygon() -> PackedVector2Array:
	var collision_polygon := get_tree().current_scene.get_node_or_null(PARK_ZONE_PATH) as CollisionPolygon2D
	if collision_polygon == null or collision_polygon.polygon.is_empty():
		push_warning("Park_trigger: '%s' não encontrado ou vazio." % PARK_ZONE_PATH)
		return PackedVector2Array()
	var world_points := PackedVector2Array()
	for point in collision_polygon.polygon:
		world_points.append(collision_polygon.to_global(point))
	return world_points

func _update_info_hint() -> void:
	if info_hint == null:
		return
	if ParkMinigameManager.can_play():
		info_hint.text = "Pressione ENTER para caçar moedas"
	else:
		info_hint.text = ParkMinigameManager.lock_reason()

func _on_body_shape_entered(_body_rid: RID, _body: CharacterBody2D, _body_shape_index: int, _local_shape_index: int) -> void:
	_update_info_hint()
	info_panel.show()
	player_inside = true

func _on_body_shape_exited(_body_rid: RID, _body: CharacterBody2D, _body_shape_index: int, _local_shape_index: int) -> void:
	info_panel.hide()
	player_inside = false
	_locked_alert_shown = false
