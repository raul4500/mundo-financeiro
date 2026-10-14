extends Node2D

func _ready() -> void:
	print("=== Testando Sistema de Y-Sort do Mapa Principal ===")
	
	# 1. Carrega cena do main_game
	var main_scene = load("res://scenes/world/main_game.tscn")
	assert(main_scene != null, "main_game.tscn deve carregar")
	var world = main_scene.instantiate()
	add_child(world)
	
	# 2. Verifica Y-Sort no nó raiz do mapa
	assert(world.y_sort_enabled == true, "main_game deve ter y_sort_enabled = true")
	print("  ok   main_game tem y_sort_enabled ativado")
	
	# 3. Verifica Ground-layers em z_index = -1
	var ground = world.get_node("Ground-layers")
	assert(ground != null, "Ground-layers deve existir")
	assert(ground.z_index == -1, "Ground-layers deve ter z_index = -1 para ficar no fundo")
	print("  ok   Ground-layers está em z_index = -1")
	
	# 4. Verifica cadeia de Y-Sort do Park e Trees
	var park = world.get_node("Park")
	assert(park != null, "Park deve existir")
	assert(park.y_sort_enabled == true, "Park deve ter y_sort_enabled = true para propagar Y-Sort")
	print("  ok   Park tem y_sort_enabled ativado")
	
	var trees = world.get_node("Park/Trees")
	assert(trees != null, "Trees deve existir")
	assert(trees.y_sort_enabled == true, "Trees deve ter y_sort_enabled = true")
	print("  ok   Trees tem y_sort_enabled ativado")
	
	# 5. Verifica todos os elementos de árvores e arbustos
	var tree_count = 0
	for child in trees.get_children():
		if child is Sprite2D:
			tree_count += 1
			assert(child.y_sort_enabled == true, "Elemento %s deve ter y_sort_enabled = true" % child.name)
			assert(child.offset.y != 0.0, "Elemento %s deve ter offset ajustado para o pé do sprite" % child.name)
	assert(tree_count >= 40, "Deve haver mais de 40 árvores/arbustos no parque")
	print("  ok   Todos os %d arbustos e árvores estão com y_sort_enabled e offset na base" % tree_count)
	
	# 6. Verifica cadeia de Y-Sort do Player container e CharacterBody2D
	var player_node = world.get_node("Player")
	assert(player_node != null, "Player container deve existir")
	assert(player_node.y_sort_enabled == true, "Player container deve ter y_sort_enabled = true")
	
	var character = world.character
	assert(character != null, "Personagem instanciado deve existir")
	assert(character.y_sort_enabled == true, "CharacterBody2D do player.tscn deve ter y_sort_enabled = true")
	print("  ok   Player container e CharacterBody2D possuem y_sort_enabled = true")
	
	# 7. Verifica todos os personagens disponíveis
	var player_scene = load("res://scenes/players/player.tscn")
	var character_scenes = [
		"res://scenes/players/raul.tscn",
		"res://scenes/players/enzo.tscn",
		"res://scenes/players/matheus.tscn",
		"res://scenes/players/melissa.tscn",
		"res://scenes/players/phillip.tscn"
	]
	
	for cs in character_scenes:
		var scn = load(cs)
		assert(scn != null, "Cena %s deve existir" % cs)
		var inst = scn.instantiate()
		assert(inst.y_sort_enabled == true, "Sprite animado %s deve ter y_sort_enabled = true" % cs)
		inst.free()
	print("  ok   Todas as variações de personagens (Raul, Enzo, Matheus, Melissa, Phillip) têm y_sort_enabled")
	
	# 8. Verifica contêineres de cenário e postes
	var scenario = world.get_node("Scenario")
	assert(scenario.y_sort_enabled == true, "Scenario deve ter y_sort_enabled = true")
	var poles = world.get_node("Light-poles")
	assert(poles.y_sort_enabled == true, "Light-poles deve ter y_sort_enabled = true")
	var buildings = world.get_node("Buildings")
	assert(buildings.y_sort_enabled == true, "Buildings deve ter y_sort_enabled = true")
	print("  ok   Scenario, Light-poles e Buildings mantêm y_sort_enabled ativo")
	
	print("=== Todos os testes de Y-Sort passaram com sucesso! ===")
	get_tree().quit(0)
