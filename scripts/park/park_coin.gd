extends Area2D

# Moeda avulsa do minigame do parque. Nasce com um tempo de vida (10s por
# padrão) mostrado em um label acima dela; some sozinha se ninguém pegar.
# Suporta cena .tscn com AnimatedSprite2D visual ou fallback automático.

signal collected
signal expired

const RADIUS := 14.0
const COLOR := Color(1.0, 0.84, 0.0)
const COLOR_OUTLINE := Color(0.6, 0.42, 0.0)

var lifetime: float = ParkMinigameManager.COIN_LIFETIME

@onready var _animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var _label: Label = $TimerLabel if has_node("TimerLabel") else null

func _ready() -> void:
	if not has_node("CollisionShape2D"):
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = RADIUS
		shape.shape = circle
		add_child(shape)

	if _label == null:
		_label = Label.new()
		_label.name = "TimerLabel"
		_label.position = Vector2(-16, -RADIUS - 26)
		_label.add_theme_font_size_override("font_size", 16)
		add_child(_label)

	_update_label()

	if _animated_sprite != null:
		if _animated_sprite.sprite_frames != null and _animated_sprite.sprite_frames.has_animation("default"):
			_animated_sprite.play("default")
	else:
		queue_redraw()

	if not body_shape_entered.is_connected(_on_body_shape_entered):
		body_shape_entered.connect(_on_body_shape_entered)

func _process(delta: float) -> void:
	lifetime -= delta
	_update_label()
	if lifetime <= 0.0:
		expired.emit()
		queue_free()

func _update_label() -> void:
	if _label != null:
		_label.text = str(int(ceil(max(lifetime, 0.0))))

func _draw() -> void:
	# Se não houver sprite configurado com frames, desenha o círculo procedural como fallback
	if _animated_sprite == null or _animated_sprite.sprite_frames == null or _animated_sprite.sprite_frames.get_frame_count("default") == 0:
		draw_circle(Vector2.ZERO, RADIUS, COLOR)
		draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 32, COLOR_OUTLINE, 2.0)

func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if not body is CharacterBody2D:
		return
	collected.emit()
	queue_free()

