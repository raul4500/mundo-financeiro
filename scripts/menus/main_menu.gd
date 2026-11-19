extends Control

@onready var continue_button = $GridContainer/start

func _ready() -> void:
	# O relogio nao para sozinho ao sair do mundo: todas as cenas de gameplay
	# ligam Global.play_time no _ready() e nenhuma o desliga ao sair. Sem esta
	# linha o tempo continuava correndo com o jogo no menu (bug 9.1).
	Global.play_time = false
	if SaveManager.has_save():
		Global.load_data()
	continue_button.visible = SaveManager.has_save() and Global.player.get("name", "") != ""

func start() -> void:
	if not SaveManager.has_save():
		return
	Global.load_data()
	if Global.player.get("name", "") == "":
		return
	FIIManager.load_data()
	Global.in_school_minigame = false
	Global.in_office = false
	Global.player_hud_hidden = false
	CameraManager.is_cinematic = false
	AlertManager.reset()
	TimeManager.reset()
	TimeManager.update_time()
	Global.force_release_all_gameplay_locks()
	Global.reestore_speed()
	TransitionManager.change_scene("res://scenes/world/main_game.tscn")

func _on_start_pressed() -> void:
	start()
	
func _on_novo_jogo_pressed() -> void:
	TransitionManager.change_scene("res://scenes/menus/choose_character.tscn")


func _on_sair_do_jogo_pressed() -> void:
	get_tree().quit()
