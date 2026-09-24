extends CharacterBody2D

var speed = Global.player["speed"]

var characters = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

var char_name = ""
var animated_player: Node = null

var clock_scene = preload("res://scenes/ui/clock.tscn")

func _ready() -> void:
	char_name = Global.player.get("name", "")
	if not characters.has(char_name):
		push_warning("Personagem inválido: '%s'. Usando personagem padrão." % char_name)
		char_name = characters.keys()[0]

	var scene = load(characters[char_name])
	animated_player = scene.instantiate()
	add_child(animated_player)

	var clock_ui = clock_scene.instantiate()
	add_child(clock_ui)

func _physics_process(delta: float) -> void:
	
	if Global.gameplay_locked:
		return
	
	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	# Normalização para diagonal
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Corrida / velocidade base
	var spd_name = "walk"
	
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
	velocity = direction * speed

	move_and_slide()
	
func _process(delta: float) -> void:
	speed = Global.player["speed"]
