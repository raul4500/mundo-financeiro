extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

@onready var sprite = $AnimatedSprite2D


func _physics_process(delta: float) -> void:

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction_x := Input.get_axis("ui_left", "ui_right")
	var direction_y := Input.get_axis("ui_up", "ui_down")
	
	if direction_x:
		sprite.play("walk")
		sprite.flip_h = false
		velocity.x = direction_x * SPEED
	else:
		sprite.play("walk")
		sprite.flip_h = true
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	if direction_y:
		sprite.play("up")
		velocity.y = direction_y * SPEED
	else:
		sprite.play("down")
		velocity.y = move_toward(velocity.y, 0, SPEED)
		
	

	move_and_slide()
