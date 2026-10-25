## Bomb Resource Script
## N64-style bombs with variable fuse durations

extends Area2D
class_name BomberBomb

# N64 Bomb types
enum BombType {
	NORMAL = 0,    # 6 second fuse, base radius
	MOD3 = 1,      # 7 second fuse, doesn't reset
	POWER = 2,     # 8 second fuse, larger radius
}

# Explosion radius in tiles
const EXPLOSION_RADIUS_TILES = 3.0

# Scheduled explosions (direction, timer)
var explosions_to_trigger = []
var bomb_active_dir = Vector2.DOWN

# Tile reference
@onready var tile_map = $TileMapLayer

# Helper: Get explosion radius by bomb type
func _get_explosion_radius(bomb_type: BombType = BombType.NORMAL) -> float:
	match bomb_type:
		BombType.NORMAL: return 3.0
		BombType.MOD3: return 3.5
		BombType.POWER: return 4.0
	return 3.0

# N64 Mod 3 behavior (blocks don't reset)
var mod3_decay_timer = 0.0
var is_mod3 = false

# Visual effects
var fuse_duration = 6.0
var show_fuse_animation = true

func _ready() -> void:
	# Initialize bomb visual
	if $TileMapLayer:
		# Add bomb sprite or marker here
		pass
		# N64-style bomb animation on ground
		modulate.a = 1.0
	
	# Set animation if showing
	if show_fuse_animation and has_node("AnimationPlayer"):
		$AnimationPlayer.play("fuse")

func _physics_process(delta: float) -> void:
	# Apply gravity and movement
	velocity.y += 980.0 * delta
	
	# Fall movement
	move_and_slide()
	
	# N64 Mod 3 block decay timer
	if is_mod3 and mod3_decay_timer > 0:
		mod3_decay_timer -= delta
	
	# Check if bomb should snap to ground (prevent falling through)
	if velocity.y > 0 and $TileMapLayer:
		# Check if we're at map bottom
		if position.y > $TileMapLayer.map_size.y * TILE_SIZE - 10:
			velocity.y = 0

func _process(delta: float) -> void:
	# Fuse timer countdown
	var now = Time.get_ticks_unix() / 1000.0
	
	# Countdown all scheduled explosions
	for i in range(len(explosions_to_trigger) - 1, -1, -1):
		var (direction, timer, fuse_duration_val, last_timer) = explosions_to_trigger[i]
		if now > timer:
			explosions_to_trigger.remove_at(i)

# REMOVED DUPLICATE _physics_process - already defined at line 52
	
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and not body.is_in_group("wall"):
		# Player or enemy hit by bomb - deal damage
		if body.has_method("take_damage"):
			body.take_damage(1.0)
		body.queue_free()

func _on_timer_timeout() -> void:
	var now = Time.get_ticks_unix() / 1000.0
	
	for i in range(len(explosions_to_trigger) - 1, -1, -1):
		var (direction, timer, fuse_duration_val, last_timer) = explosions_to_trigger[i]
		_spawn_explosion_direction(direction, now, fuse_duration_val)
	
	# Main timer explosion
	spawn_explosion(bomb_active_dir, now)
	
	queue_free()

func spawn_explosion(direction: Vector2, trigger_time: float, fuse_duration: float = 6.0) -> void:
	_spawn_explosion_direction(direction, trigger_time, fuse_duration)

func _spawn_explosion_direction(direction: Vector2, trigger_time: float, fuse_duration: float = 6.0) -> void:
	explode(direction, trigger_time, fuse_duration)

# Core explosion function - create explosion effect
func explode(direction: Vector2, trigger_time: float, fuse_duration: float = 6.0) -> void:
	# Check if bomb exists (for Mod 3 blocks that can't be destroyed)
	if $TileMapLayer and not can_destroy_tile(direction):
		return
	
	# Calculate explosion center based on bomb position and direction
	var bomb_pos = $TileMapLayer.local_to_global(position)
	var explosion_center = bomb_pos + direction * TILE_SIZE * 2.0
	
	# Create explosion scene
	var explosion_scene = preload("res://scenes/explosion.tscn")
	if not explosion_scene:
		push_error("Explosion scene not found!")
		return
	
	var explosion = explosion_scene.instantiate()
	
	# Set explosion properties
	explosion.shockwave_direction = direction
	explosion.explosion_center = explosion_center
	explosion.timer.wait_time = fuse_duration
	explosion.check_collisions(explosion_center)
	
	# Add to scene tree
	call_deferred("queue_free")
	get_parent().add_child(explosion)