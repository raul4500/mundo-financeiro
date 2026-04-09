extends CharacterBody2D


const SPEED = 50.0

@onready var sprite = $AnimatedSprite2D


func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	
	if direction_x > 0:
		sprite.play("walk")
		sprite.flip_h = false
		velocity.x = direction_x * SPEED
	elif direction_x < 0:
		sprite.play("walk")
		sprite.flip_h = true
		velocity.x = direction_x * SPEED
	elif direction_y > 0:
		sprite.play("down")
		velocity.y = direction_y * SPEED
	elif direction_y < 0:
		sprite.play("up")
		velocity.y = direction_y * SPEED
	else:
		sprite.play("idle")
		velocity.x = 0
		velocity.y = 0

	move_and_slide()
