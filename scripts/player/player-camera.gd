extends Camera2D



var cinematic_mode := false
var target_position := Vector2.ZERO

func _ready():
	# mantém seu smoothing
	position_smoothing_enabled = true

func _process(delta):
	if cinematic_mode:
		return

# Entrou em modo de cutscene
func start_cinematic():
	cinematic_mode = true
	# desligamos o smoothing temporariamente
	# para o tween controlar exatamente a câmera
	position_smoothing_enabled = false

# Volta para seguir o jogador
func stop_cinematic():
	cinematic_mode = false
	position_smoothing_enabled = true
	# garante que volta exatamente para o player
	position = Vector2.ZERO



# Move a câmera para algum lugar
func move_to(
	position_global: Vector2,
	duration := 1.5
):
	var tween = create_tween()


	tween.set_trans(
		Tween.TRANS_SINE
	)


	tween.set_ease(
		Tween.EASE_IN_OUT
	)



	# Como a câmera é filha do player,
	# usamos posição global
	tween.tween_property(
		self,
		"global_position",
		position_global,
		duration
	)



	await tween.finished
