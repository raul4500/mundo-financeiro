extends CharacterBody2D


var characters = {
	"Raul": "res://scenes/players/raul.tscn",
	"Matheus": "res://scenes/players/matheus.tscn",
	"Phillip": "res://scenes/players/phillip.tscn",
	"Melissa": "res://scenes/players/melissa.tscn",
	"Enzo": "res://scenes/players/enzo.tscn"
}

var char_name = ""
var animated_player: Node = null


func _ready() -> void:
	char_name = Global.player.get("name", "")
	if not characters.has(char_name):
		push_warning("Personagem inválido: '%s'. Usando personagem padrão." % char_name)
		char_name = characters.keys()[0]

	var scene = load(characters[char_name])
	animated_player = scene.instantiate()
	add_child(animated_player)


const SPEED = 100.0
const JUMP_VELOCITY = -400.0


func _physics_process(delta: float) -> void:
	if Global.gameplay_locked:
		return

	animated_player.play("walk")
	if not is_on_floor():
		velocity += get_gravity() * delta * 1.5
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	velocity.x = SPEED
	move_and_slide()
