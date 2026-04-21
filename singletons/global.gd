extends Node

# Variável para armazenar a referência do nó do jogador
var player: Node2D = null
var money: float

func _ready() -> void:
	money = Data.data["money"]
	print("global loaded")
	

# Função opcional para pegar a posição mais facilmente
func get_player_position() -> Vector2:
	if player:
		return player.global_position
	return Vector2.ZERO # Retorna zero se o player não existir
