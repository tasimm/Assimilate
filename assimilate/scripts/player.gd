extends CharacterBody2D

@export var speed := 200
var weapons = []
var max_weapons := 3
var health := 100
var max_health := 100
var is_dead := false
var is_invincible := false

@onready var anim = $Sprite2D

func _physics_process(delta):
	var input_vector = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	velocity = input_vector.normalized() * speed
	move_and_slide()

	update_animation(input_vector)

var last_direction = "down"	
func update_animation(input_vector):
	if input_vector == Vector2.ZERO:
		play_idle()
		return

	if abs(input_vector.x) > abs(input_vector.y):
		if input_vector.x > 0:
			anim.play("run_right")
			last_direction = "right"
		else:
			anim.play("run_left")
			last_direction = "left"
	else:
		if input_vector.y > 0:
			anim.play("run_down")
			last_direction = "down"
		else:
			anim.play("run_up")
			last_direction = "up"
			
func play_idle():
	anim.play("idle_" + last_direction)
	
func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):
		attack()
		
	if is_dead:
		return
		
func attack():
	var bodies = $Area2D.get_overlapping_bodies()

	for body in bodies:
		if body == self:
			continue

		if body.has_method("take_damage") and "state" in body:
			if body.state == body.State.ENEMY:
				body.take_damage()
			
func add_weapon(enemy):
	if enemy in weapons:
		return

	if weapons.size() >= max_weapons:
		var old_weapon = weapons.pop_front()

		if is_instance_valid(old_weapon):
			old_weapon.queue_free()

	weapons.append(enemy)
	
func take_damage(amount):
	if is_dead:
		return

	health -= amount

	if health <= 0:
		is_dead = true
		play_death()
		return

	flash()
	
func disable_all_collisions():
	set_collision_layer(0)
	set_collision_mask(0)

	# Disable any hitbox/Area2D
	if has_node("Area2D"):
		$Area2D.monitoring = false

	# Disable ALL children collision shapes
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
		
func play_death():
	
	set_physics_process(false)
	set_process(false)

	# Disable attack hitbox
	if has_node("Area2D"):
		$Area2D.monitoring = false

	velocity = Vector2.ZERO

	$Sprite2D.play("death")

	
	await get_tree().create_timer(0.5).timeout

	die()
		
func die():
	await get_tree().create_timer(0.2).timeout
	get_tree().paused = true
	get_parent().show_game_over()
	
func flash():
	modulate = Color(1, 0.7, 0.7)

	await get_tree().create_timer(0.1).timeout

	modulate = Color(1, 1, 1)

func _ready():
	reset_player()
	
func reset_player():
	is_dead = false
	is_invincible = false

	health = max_health

	#Restore collisions
	set_collision_layer(1)
	set_collision_mask(1)

	# Restore hitbox
	if has_node("Area2D"):
		$Area2D.monitoring = true

	# Restore processing
	set_physics_process(true)
	set_process(true)

	# Reset visuals
	modulate = Color(1, 1, 1)
