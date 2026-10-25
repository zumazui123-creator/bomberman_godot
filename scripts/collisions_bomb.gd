## Bomb Collision Script
## Handles bomb collisions with walls, enemies, and boundaries
## 🧨 BOMB PHYSICS! 💥

class_name BombCollisionHandler
extends Area2D

const BOMB_SPEED = 400.0
const BOUNCE_FORCE = 200.0

var current_velocity := Vector2.ZERO
var collision_count := 0

@g子曰f _ready() -> void:
	bump_velocity()

func _physics_process(delta: float) -> void:
	 velocity.y += 980.0 * delta
	
	# Move with collision
	move_and_slide()
	
	# Check if hit a wall
	if velocity.x != 0:
		if not is_on_floor():
			bump_velocity()
	
	# Check if hit a wall
	if not is_on_floor():
		bump_velocity()

# Change bomb velocity on collision
func bump_velocity() -> void:
	collision_count += 1
	
	if collision_count > 5:
		# Stop bomb if it hits a wall
		velocity = Vector2.ZERO
		queue_free()
		return
	
	# Calculate new velocity
	velocity.x = BOMB_SPEED
	velocity.y = 0
	
	# Change collision layer/mask
	collision_layer |= 1  # | LAYER_WALL, LAYER_FLOOR
	collision_mask |= 1   # | LAYER_WALL, LAYER_FLOOR

# Handle collision with enemy
func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(1.0)
	
	queue_free()