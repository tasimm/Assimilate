extends CharacterBody2D

@export var speed := 100
var player = null
var health := 1
var can_hit := true
var is_hit := false

enum State { ENEMY, WEAPON }
var state = State.ENEMY

# enemy orbits around player after it dies
var player_ref = null
var orbit_angle := 0.0
var orbit_radius := 60
var orbit_speed := 4

@onready var anim = $Sprite2D
@export var type := "chaser" # enemy type
var shoot_timer := 0

func _physics_process(delta):
	if state == State.ENEMY:
		update_enemy_animation()
	
	if player == null or state != State.ENEMY:
		return

	match type:
		"chaser":
			chase_player()

		"shooter":
			shooter_behavior(delta)

		"tank":
			chase_player() # same movement, different stats

	var direction = (player.global_position - global_position).normalized()

	velocity = direction * speed
	move_and_slide()
	
func _ready():
	match type:
		"chaser":
			speed = 100
			health = 1
			anim.play("chaser_run")

		"shooter":
			speed = 0
			health = 1
			anim.play("shooter_idle")

		"tank":
			speed = 50
			health = 3
			anim.play("tank_run")

func update_enemy_animation():
	match type:
		"chaser":
			anim.play("chaser_run")

		"shooter":
			anim.play("shooter_idle")

		"tank":
			anim.play("tank_run")
			
func take_damage():
	if state != State.ENEMY:
		return

	health -= 1

	play_hit_animation()

	if health <= 0:
		die_with_delay()
		
func die_with_delay():
	await get_tree().create_timer(0.1).timeout

	# make sure it hasn't already converted
	if state != State.ENEMY:
		return

	die()

func play_hit_animation():
	var hit_anim = type + "_hit"

	if not anim.sprite_frames.has_animation(hit_anim):
		print("Missing animation:", hit_anim)
		return

	is_hit = true

	anim.stop() # IMPORTANT
	anim.play(hit_anim)

	await anim.animation_finished

	is_hit = false
				
func die():
	convert_to_weapon()
	
func convert_to_weapon():
	if state == State.WEAPON:
		return

	state = State.WEAPON

	velocity = Vector2.ZERO
	set_physics_process(false)

	# 🔥 ADD THESE
	set_collision_layer(0)
	set_collision_mask(0)

	# optional (extra safe)
	$CollisionShape2D.disabled = true

	global_position = player_ref.global_position

	player_ref.add_weapon(self)
	
func _process(delta):
	if state == State.WEAPON and player_ref != null:
		orbit_angle += orbit_speed * delta

		var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
		global_position = player_ref.global_position + offset
	
	if type == "shooter":
		shoot_timer += delta
	if shoot_timer > 1.0:
		shoot_timer = 0
		shoot_nearest_enemy()
		
func _on_area_2d_body_entered(body):
	if not can_hit:
		return

	if body == self:
		return


	if body.has_method("take_damage") and not "state" in body:

		if body.has_method("is_dead") and body.is_dead:
			return

		can_hit = false
		body.take_damage(1)

		await get_tree().create_timer(0.3).timeout
		can_hit = true
		return

	if state == State.WEAPON:
		if body.has_method("take_damage") and "state" in body:
			if body.state == State.ENEMY:
				can_hit = false
				body.take_damage()

				await get_tree().create_timer(0.2).timeout
				can_hit = true
		
func chase_player():
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func shooter_behavior(delta):
	velocity = Vector2.ZERO
	shoot_timer += delta

	if shoot_timer > 1.5:
		shoot_timer = 0
		shoot()
		
func shoot():
	if player != null:
		player.take_damage(1)
		
func shoot_nearest_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")

	for e in enemies:
		if e.state == State.ENEMY:
			e.take_damage()
			break
