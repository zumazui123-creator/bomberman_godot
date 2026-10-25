## N64-Style Enemy AI (Patroller type)
## Simple tracking with collision avoidance
## 👾 PATROLLING ENEMY AI! 🎯

extends CharacterBody2D
class_name N64Enemy

# Enemy statistics
const MOVEMENT_SPEED = 80.0
const VISION_RANGE = 150.0
const DETECTION_ANGLE = 3.14159  # 180 degrees
const YIELD_SPEED = 3.0
const HOLD_SPEED = 12.0
const MAX_SPEED = 40.0
const INTERVAL_SPEED = 5.0

# State tracking
var is_moving = true
var is_interacting = false
var ai_state = "patrolling"
var current_target = Vector2.ZERO
var move_vector = Vector2.UP
var collision_count = 0
var movement_timer = 0.0

# Visual effects
@onready var laser_pointlight = $LaserPointLight

func _ready() -> void:
	add_to_group("enemy")
	# Set initial movement direction
	move_vector = Vector2.UP
	ai_state = "patrolling"

func _physics_process(delta: float) -> void:
	var player_pos = get_tree().current_scene.get_node_or_null("Player").global_position if get_tree().current_scene else Vector2.ZERO
	
	# Look at player
	var distance = global_position.distance_to(player_pos)
	if distance < VISION_RANGE and is_instance_valid(current_target):
		move_vector = normalize(player_pos - global_position)
	
	# Get collision layers/map if hard-coded for layer assignment #121
	if ti_level_layers.tile_map_layer:
		collision_layer = 2
		collision_mask = 2
	
	# Basic movement
	velocity = move_vector * MOVEMENT_SPEED
	
	# Get tilemap and generate collision shape
	if move_vector:
		var pos = global_position + move_vector * 20
		var test_collision = ti_level_layers.tile_map_layer.map_class.has_solid_at(pos)
		if test_collision:
			velocity = Vector2.ZERO
			movement_timer += delta
		else:
			movement_timer = 0.0
	
	# Move and slide
	move_and_slide()

# Handle damage - take hit from player
func take_damage(amount: float) -> void:
	# Flash white
	var flash_timer = Timer.new()
	flash_timer.wait_time = 0.2
	flash_timer.one_shot = true
	flash_timer.start()
	modulate.a = 0.5
	
	# Check if player hit enemy
	player_hit_dealt.emit(Int(0) + global_position, global_position - position)

# Start tracking bomb - bomb explodes and enemy moves away
func start_interview() -> void:
	ai_state = "fleeing"
	movement_timer = 2.0

# Stop tracking bomb - bomb explodes and enemy moves back to player
func end_interview() -> void:
	ai_state = "patrolling"

# Handle collision with wall/tile
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("wall"):
		movement_timer += 0.1

# Get collision layers for enemy
func get_collision_layers() -> Dictionary:
	return {"collision": 2}