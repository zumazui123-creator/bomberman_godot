## Player Movement Script
## - Acceleration/friction-based movement 🏃‍♂️
## - Explosion timer increasing radius 💥
## - Invincibility frames 🛡️
## - Multi-direction bomb drops 🧨
## - Smooth controls with collision handling ⚡

extends CharacterBody2D
class_name BombermanPlayer

# Movement constants
const SPEED = 200.0
const ACCELERATION = 2000.0
const FRICTION = 1500.0
const JUMP_VELOCITY = -400.0

# Explosion radius (N64 bomb increases with time)
const EXPLOSION_BASE_RADIUS = 1.5
const EXPLOSION_MAX_RADIUS = 6.0
const EXPLOSION_GROWTH_RATE = 0.08
const EXPLOSION_DURATION = 2.0

# Invincibility
const INVISIBILITY_DURATION = 3.0

# Multi-bomb settings
const MAX_BOMBS = 9
const BOMB_FALL_SPEED = 400.0
const BOMB_DROP_DELAY = 0.1

# Collision constants
const COL_FLOOR = 1
const COL_air = 2

# Signal declarations
signal bomb_dropped(dropped_bomb)
signal player_hit_dealt damage
signal player_died

# Explosion direction tracking
var explosion_directions = []
var last_drop_time = 0.0
var current_invincible_time = 0.0
var invincible_timer = Timer.new()

# Tilemap reference
@onready var tile_map_layer = $TileMapLayer
@onready var laser_pointlight = $LaserPointLight

# Debug
# var show_bomb_paths = true

func _ready() -> void:
	init_timers()
	add_to_group("player")
	handle_invincibility_start()

# Initialize timers
func init_timers() -> void:
	if invincible_timer:
		invincible_timer.one_shot = true
		invincible_timer.wait_time = INVISIBILITY_DURATION
		invincible_timer.connect("timeout", _on_invincibility_timeout)
		add_child(invincible_timer)

func _physics_process(delta: float) -> void:
	# Apply gravity
	velocity.y += 9.8 * 60.0 * delta

func _input(event: InputEvent) -> void:
	if is_instance_valid(get_tree()) and get_tree().current_scene is Node2D:
		# Movement with acceleration/friction
		func _move(delta: float) -> void:
			# Apply acceleration/fraction
			if Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
				# Accelerate
				if velocity.x < SPEED and Input.is_action_pressed("move_right"):
					velocity.x += ACCELERATION * delta
					velocity.y = 0
				elif velocity.x > -SPEED and Input.is_action_pressed("move_left"):
					velocity.x -= ACCELERATION * delta
					velocity.y = 0
			elif velocity.x > 0:
				velocity.x = max(velocity.x - FRICTION * delta, -SPEED/2)
			elif velocity.x < 0:
				velocity.x = min(velocity.x + FRICTION * delta, SPEED/2)
	
			# Check if on ground for jumping
			var on_floor = is_on_floor()
			if not on_floor:
				# Can't jump in air
				velocity.y = 0
	
			if velocity.x != 0:
				# Move with collision
				move_and_slide()
			else:
				# Vertical movement only
				move_and_slide()

# Drop bomb with acceleration/friction
# REMOVED DUPLICATE _input function - already defined at line 70

# Drop bomb with acceleration/friction
func _drop_bomb() -> void:
	var now = Time.get_ticks_unix() / 1000.0
	if now - last_drop_time < BOMB_DROP_DELAY:
		return

	if explosion_directions.is_empty() or len(explosion_directions) > MAX_BOMBS:
		explosion_directions.clear()
		return

	last_drop_time = now

	for direction in explosion_directions:
		bomb_dropped.emit(direction.copy())

	explosion_directions.clear()

# Check if player can collide at position
func can_collide(position: Vector2) -> bool:
	if not tile_map_layer:
		return true
	# Check if position is not solid
	var collision_layer = tile_map_layer.get_used_cells_in_rect(
		Rect2(position.x - 16, position.y - 16, 32, 32)
	)
	if not collision_layer.is_empty():
		return false
	return true

# Handle invincibility state
func handle_invincibility_start() -> void:
	current_invincible_time = INVISIBILITY_DURATION
	if laser_pointlight:
		laser_pointlight.mode = PointLight2D.MODE_DISABLED
		laser_pointlight.disabled = true
	if invincible_timer:
		invincible_timer.start()

func _on_invincibility_timeout() -> void:
	# Invincibility ended
	current_invincible_time = 0.0
	if laser_pointlight:
		laser_pointlight.mode = PointLight2D.MODE_DISABLED
		laser_pointlight.disabled = false

# Take damage and handle collision
func _on_body_entered(body: Node2D) -> void:
	if not is_in_group("enemy"):
		return

	if body.has_method("damage_player"):
		body.damage_player(1.0, position, direction_to_body(body))

func damage_player(damage: float, hit_position: Vector2 = null, hit_direction: Vector2 = Vector2.ZERO) -> void:
	if current_invincible_time > 0:
		return

	handle_invincibility_start()
	
	# Emit damage signal
	player_hit_dealt.emit(damage, hit_position, hit_direction)
	
	# Apply damage effect
	var laser_power = 1.0
	get_child(0).lasers.append(Vector2(hit_direction.x, hit_direction.y) * laser_power)

func _process(delta: float) -> void:
	# Visual effects
	if current_invincible_time > 0:
		# Flash alternating
		if floor(current_invincible_time) % 2 == 0:
			modulate.a = 0.5
		else:
			modulate.a = 1.0
	
	# Laser pointlight tracking
	if laser_pointlight and not is_on_floor():
		# Track position
		laser_pointlight.position = position
