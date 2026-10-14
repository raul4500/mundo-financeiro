extends Camera2D



var cinematic_mode := false
var target_position := Vector2.ZERO
var current_tween: Tween = null

signal move_completed

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
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	cinematic_mode = false
	position_smoothing_enabled = true
	# garante que volta exatamente para o player
	position = Vector2.ZERO
	move_completed.emit()

func cancel_movement():
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	move_completed.emit()

# Move a câmera para algum lugar
func move_to(
	position_global: Vector2,
	duration := 1.5
):
	if current_tween != null and current_tween.is_valid():
		current_tween.kill()
		current_tween = null

	if duration <= 0.0:
		global_position = position_global
		return

	current_tween = create_tween()
	current_tween.set_trans(Tween.TRANS_SINE)
	current_tween.set_ease(Tween.EASE_IN_OUT)

	# Como a câmera é filha do player,
	# usamos posição global
	current_tween.tween_property(
		self,
		"global_position",
		position_global,
		duration
	)

	var on_finished = func():
		current_tween = null
		move_completed.emit()

	current_tween.finished.connect(on_finished)
	await move_completed

