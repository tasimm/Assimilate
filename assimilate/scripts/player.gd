extends CharacterBody2D

@export var speed := 200
var weapons = []
var max_weapons := 3

func _physics_process(delta):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	
	velocity = input_vector.normalized() * speed
	move_and_slide()
	
#func _process(delta):
	#if Input.is_action_just_pressed("ui_accept"):
		#attack()
		
#func attack():
	#var bodies = $Area2D.get_overlapping_bodies()
	#
	#for body in bodies:
		#if body.has_method("take_damage"):
			#body.take_damage()
			
func add_weapon(enemy):
	if weapons.size() >= max_weapons:
		var old_weapon = weapons.pop_front()
		old_weapon.queue_free()

	weapons.append(enemy)
