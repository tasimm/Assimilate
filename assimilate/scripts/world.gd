extends Node2D

@onready var player = $player
@onready var spawn_area = $SpawnArea/CollisionShape2D
@onready var health_label = $CanvasLayer/Health
@onready var health_bar = $CanvasLayer/HealthBar/BarFill
@onready var timer_label = $CanvasLayer/Timer
@onready var game_over_label = $CanvasLayer/GameOver
@export var enemy_scene: PackedScene

var time_survived := 0.0
var max_bar_width := 0.0

func _ready():
	max_bar_width = health_bar.scale.x
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.player = player
		enemy.player_ref = player

func _process(delta):
	var health_percent = float(player.health) / player.max_health
	health_bar.scale.x = health_percent

	if not get_tree().paused:
		time_survived += delta
		
	timer_label.text = "Time: " + str(int(time_survived))
	health_label.text = "HP: " + str(player.health)
	
	if get_tree().paused and Input.is_action_just_pressed("restart"):
		get_tree().paused = false
		get_tree().reload_current_scene()
	
func _on_spawn_timer_timeout():
	spawn_enemy()
	
func spawn_enemy():
	var enemy = enemy_scene.instantiate()

	var shape = spawn_area.shape
	var extents = shape.extents

	var x = randf_range(-extents.x, extents.x)
	var y = randf_range(-extents.y, extents.y)

	var spawn_pos = spawn_area.global_position + Vector2(x, y)

	enemy.global_position = spawn_pos

	enemy.player = player
	enemy.player_ref = player

	var types = ["chaser", "shooter", "tank"]
	enemy.type = types.pick_random()

	add_child(enemy)
	
func show_game_over():
	game_over_label.visible = true
	#if get_tree().paused and event.is_action_pressed("restart"):
		#get_tree().reload_current_scene()
