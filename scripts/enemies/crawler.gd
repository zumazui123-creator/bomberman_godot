## Crawler Enemy Script
## Slow-moving enemy with tight cornering
## 🐛 CRAWLER ENEMY! 🐌

extends CharacterBody2D
class_name CrawlerEnemy

const MOVEMENT_SPEED = 50.0
const SLOW_SPEED = 25.0
const SLOW_RESISTANCE = 1000.0
const SLOW_ENERGY = 10000.0

var enemy_type = 0
var face_direction = Vector2.DOWN
var flashlight_color = Color(1.0, 1.0, 1.0)
var is_moving = true
var ai_state = "patrolling"
var current_target = Vector2.ZERO
var move_vector = Vector2.UP
var collision_count = 0.0
var movement_timer = 0.0

@onready var laser_pointlight = $LaserPointLight

func _ready() -> void:
	add_to_group("enemy")
	move_vector = Vector2.UP
	ai_state = "patrolling"
	enemy_type = randi() % 4

func _physics_process(delta: float) -> void:
	var player_pos = get_tree().current_scene.get_node_or_null("Player").global_position if get_tree().current_scene else Vector2.ZERO
	
	var distance = global_position.distance_to(player_pos)
	if distance < 300.0 and player_pos.distance_to(current_target):
		move_vector = normalize(player_pos - global_position)
	else:
		move_vector = normalize(current_target - global_position)
	
	collision_layer = 2
	collision_mask = 2
	
	velocity = move_vector * MOVEMENT_SPEED
	
	if move_vector:
		var pos = global_position + move_vector * 20
		if ti_level_layers.tile_map_layer.map_class.has_solid_at(pos):
			velocity = Vector2.ZERO
	
	move_and_slide()

func take_damage(amount: float) -> void:
	var flash_timer = Timer.new()
	flash_timer.wait_time = 0.2
	flash_timer.one_shot = true
	flash_timer.start()
	modulate.a = 0.5

func on_die() -> void:
	if fade_uplight:
		fade_uplight.light_end_stage = 1.0
		fade_uplight.light_end_stage = 0.0
		fade_uplight.light_end_duration = 0.2

func get_collision_layers() -> Dictionary:
	return {"collision": 2}

func render_target() -> Color:
	return Color.BLUE

func get_base_score() -> int:
	return int(50 * (enemy_type + 1))

func get_move_vector() -> Vector2:
	return move_vector