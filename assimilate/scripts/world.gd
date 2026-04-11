extends Node2D

@onready var player = $player

func _ready():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.player = player
		enemy.player_ref = player
		enemy.convert_to_weapon()
