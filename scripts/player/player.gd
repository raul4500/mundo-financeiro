extends CharacterBody2D

var SPEED = 70.0

# Auto-run (usado pelo minigame para a entrada do jogador correndo)
var auto_run_active := false
var auto_run_target_x := 0.0
var auto_run_speed := 140.0

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

func start_auto_run(target_x: float, speed: float = 140.0) -> void:
	auto_run_active = true
	auto_run_target_x = float(target_x)
	auto_run_speed = float(speed)

func stop_auto_run() -> void:
	auto_run_active = false

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
	
	# Se o auto_run estiver ativo, forçamos o movimento horizontal até o alvo.
	var direction = Vector2.ZERO
	if auto_run_active:
		var dx = auto_run_target_x - global_position.x
		if abs(dx) <= 4.0:
			# chegou no destino
			auto_run_active = false
			direction = Vector2.ZERO
		else:
			# dirige sempre na direção do alvo, sem mudança no eixo Y
			direction = Vector2(sign(dx), 0)
			SPEED = auto_run_speed
	else:
		direction = Vector2(
			Input.get_axis("move_left", "move_right"),
			Input.get_axis("move_up", "move_down")
		)

	# Normalização para diagonal
	if direction != Vector2.ZERO:
		direction = direction.normalized()

	# Corrida / velocidade base
	var spd_name = "walk"
	# Durante auto_run mantemos velocidade configurada acima
	if not auto_run_active:
		SPEED = 70.0

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
