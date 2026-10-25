## N64-Style Fast Enemy (Tracer type)
## Multiple types, different speeds, corner well
## 🏃‍♂️ FAST ENEMY AI! ⚡

extends CharacterBody2D
class_name FastEnemy

# Enemy statistics
const MOVEMENT_SPEED = 120.0
const TARGET_SPEED = 16.0
const SLOW_SPEED = 8.0
const SLOW_RESISTANCE = 1000.0
const SLOW_ENERGY = 10000.0

# Enemy variants
const TYPE_SPEED = 90.0
const TYPE_BIG = 120.0
const TYPE_FAST = 130.0
const TYPE_SLOW = 80.0

# Type variants
var enemy_type = 0  # 0-3 different looks
var face_direction = Vector2.DOWN
var flashlight_color = Color(1.0, 1.0, 1.0)

# State tracking
var is_moving: bool = true
var ai_state: String = "patrolling"
var current_target: Vector2 = Vector2.ZERO

# Visual effects
@onready var laser_pointlight = $LaserPointLight
@onready var fade_uplight = $PlayerFadeFlash

func _ready() -> void:
	add_to_group("enemy")
	# Set initial movement direction
	move_vector = Vector2.UP
	ai_state = "patrolling"
	# Set type based on order
	enemy_type = randi() % 4

func _physics_process(delta: float) -> void:
 해를 treat 판정
	var player_pos = get_tree().current_scene.get_node_or_null("Player").global_position if get_tree().current_scene else Vector2.ZERO
	
	# Look at player
	var distance = global_position.distance_to(player_pos)
	if distance < 300.0 and player_pos.distance_to(current_target):
		move_vector = _reference_to_player(player_pos - global_position)
	else:
		move_vector = normalize(current_target - global_position)
	
	# Get collision layers/map if hard-coded for layer assignment #121
	if ti_level_layers.tile_map_layer:
		collision_layer = 2
		collision_mask = 2
	
	if not ti_level_layers.tile_map_layer:
		collision_layer = 2
		collision_mask = 2
	
	# Basic movement
	velocity = move_vector * MOVEMENT_SPEED
	
	# Get tilemap and generate collision shape
	if move_vector:
		var pos = global_position + move_vector * 20
		if ti_level_layers.tile_map_layer.map_class.has_solid_at(pos):
			push_error("Hit solid tile")
			velocity = Vector2.ZERO
	
	# Move and slide
	move_and_slide()

func _reference_direction(player_target: Vector2) -> Vector2:
	var angle = angle_to(player_target)
	velocity.x = sin(angle) * MOVEMENT_SPEED
	velocity.y = -cos(angle) * MOVEMENT_SPEED
	return velocity

func _get_target() -> Vector2:
	# Get enemy position to return
	var enemy_position = global_position
	return enemy_position

# Handle damage from player
func take_damage(amount: float) -> void:
	# Flash white
	var flash_timer = Timer.new()
	flash_timer.wait_time = 0.2
	flash_timer.one_shot = true
	flash_timer.start()
	modulate.a = 0.5

# Handle collision with wall
func on_die() -> void:
	# Add death animation
	if fade_uplight:
		fade_uplight.light_end_stage = 1.0
		fade_uplight.light_end_stage = 0.0
		fade_uplight.light_end_duration = 0.2

# Get collision layers for enemy
func get_collision_layers() -> Dictionary:
	return {"collision": 2}

# Get render target color
func render_target() -> Color:
	return Color.RED

# Get base score for enemy
func get_base_score() -> int:
	return int(100 * (enemy_type + 1))