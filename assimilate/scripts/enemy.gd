extends CharacterBody2D

@export var speed := 100
var player = null
var health := 1
var can_hit := true

enum State { ENEMY, WEAPON }
var state = State.ENEMY

# enemy orbits around player after it dies
var player_ref = null
var orbit_angle := 0.0
var orbit_radius := 60
var orbit_speed := 4

@export var type := "chaser" # enemy type
var shoot_timer := 0

func _physics_process(delta):
	
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
	set_process(true)

func take_damage():
	health -= 1
	if health <= 0:
		die()
		
func die():
	convert_to_weapon()
	
func convert_to_weapon():
	if player_ref == null:
		print("ERROR: player_ref is null")
		return

	state = State.WEAPON

	velocity = Vector2.ZERO
	set_physics_process(false)
	set_collision_layer(0)
	set_collision_mask(0)

	global_position = player_ref.global_position

	player_ref.add_weapon(self)
	
func _process(delta):
	if state != State.WEAPON or player_ref == null:
		return

	orbit_angle += orbit_speed * delta

	var offset = Vector2(cos(orbit_angle), sin(orbit_angle)) * orbit_radius
	global_position = player_ref.global_position + offset
		
func _on_area_2d_body_entered(body):
	if state != State.WEAPON or not can_hit:
		return

	if body == self:
		return

	if body.has_method("take_damage"):
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
