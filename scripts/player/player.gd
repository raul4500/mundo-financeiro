extends CharacterBody2D

var SPEED = 70.0

var characters = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

var char_name = Global.player.get("name", "")
var scene = load(characters[char_name])
var animated_player = scene.instantiate()

var clock_scene = preload("res://scenes/ui/clock.tscn")


func _ready() -> void:
	if not characters.has(char_name):
		push_error("Personagem inválido")
		get_tree().quit()
	add_child(animated_player)
	
	var event_url = load("res://scenes/ui/event_message.tscn")
	var event_ui = event_url.instantiate()
	add_child(event_ui)
	
	var clock_ui = clock_scene.instantiate()
	add_child(clock_ui)

func _physics_process(delta: float) -> void:
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	# Normalização para diagonal
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Corrida
	var spd_name = "walk"
	#if Input.is_action_pressed("run"):
	#	SPEED = 140.0
	#	spd_name = "run"
	#else:
	SPEED = 70.0
		#spd_name = "walk"

	# Animação
	if direction.x < 0:
		animated_player.flip_h = true
		animated_player.play(spd_name)
	elif direction.x > 0:
		animated_player.flip_h = false
		animated_player.play(spd_name)
	elif direction.y < 0 and direction.x == 0:
		animated_player.play("up")
	elif direction.y > 0:
		animated_player.play("down")
	else:
		animated_player.play("default")
	# Aplica velocidade
	velocity = direction * SPEED

	move_and_slide()
