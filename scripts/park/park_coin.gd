extends Area2D

# Moeda avulsa do minigame do parque. Nasce com um tempo de vida (10s por
# padrão) mostrado em um label acima dela; some sozinha se ninguém pegar.
# Toda a aparência é desenhada em _draw() para não depender de um asset novo.

signal collected
signal expired

const RADIUS := 14.0
const COLOR := Color(1.0, 0.84, 0.0)
const COLOR_OUTLINE := Color(0.6, 0.42, 0.0)

var lifetime: float = ParkMinigameManager.COIN_LIFETIME
var _label: Label

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = RADIUS
	shape.shape = circle
	add_child(shape)

	_label = Label.new()
	_label.position = Vector2(-16, -RADIUS - 26)
	_label.add_theme_font_size_override("font_size", 16)
	add_child(_label)
	_update_label()

	body_shape_entered.connect(_on_body_shape_entered)

func _process(delta: float) -> void:
	lifetime -= delta
	_update_label()
	if lifetime <= 0.0:
		expired.emit()
		queue_free()

func _update_label() -> void:
	_label.text = str(int(ceil(max(lifetime, 0.0))))

func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, COLOR_OUTLINE, 2.0)

func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if not body is CharacterBody2D:
		return
	collected.emit()
	queue_free()
