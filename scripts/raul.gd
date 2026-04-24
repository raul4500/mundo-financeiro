extends CharacterBody2D

var SPEED = 70.0

@onready var animated_player = $AnimatedSprite2D

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

func _exit_tree():
	Global.player = {}
