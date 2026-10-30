## Bomb
## N64-style ground bomb: fuse countdown, four-directional explosion,
## brick destruction, chain reactions and enemy damage.

extends Area2D
class_name BomberBomb

const SPRITE_PATH := "res://Assets/Bombs/bomb.png"
const FUSE_DURATION := 2.5
const POINTS_PER_BOMB := 10

signal exploded

var bomb_radius: int = 1
var owner_player: Node2D = null
var level_manager: LevelManager = null
var collision_manager: CollisionManager = null
var bomb_rules: BombCollisionHandler = null

var _fuse_time := FUSE_DURATION
var _exploded := false

func _ready() -> void:
	add_to_group("bombs")
	monitoring = false  # damage is applied via cell queries, not overlaps
	var shape := RectangleShape2D.new()
	shape.size = Vector2(26.0, 26.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	add_child(collision)
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(SPRITE_PATH):
		sprite.texture = load(SPRITE_PATH)
	else:
		sprite.texture = _make_fallback_texture()
	sprite.scale = Vector2.ONE * 0.2
	add_child(sprite)

static func _make_fallback_texture() -> Texture2D:
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var d := Vector2(x - 7.5, y - 8.5).length()
			if d < 6.0:
				image.set_pixel(x, y, Color(0.15, 0.15, 0.18))
			elif d < 7.0:
				image.set_pixel(x, y, Color(0.9, 0.2, 0.1))
			else:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	return ImageTexture.create_from_image(image)

func setup(
	p_level_manager: LevelManager,
	p_collision_manager: CollisionManager,
	p_bomb_rules: BombCollisionHandler
) -> void:
	level_manager = p_level_manager
	collision_manager = p_collision_manager
	bomb_rules = p_bomb_rules

func _process(delta: float) -> void:
	if _exploded:
		return
	if not GameStateManager.is_playing():
		return
	_fuse_time -= delta
	# Blink faster during the final second.
	if _fuse_time < 1.0:
		modulate.a = 1.0 if fmod(_fuse_time, 0.3) < 0.15 else 0.45
	if _fuse_time <= 0.0:
		explode()

## External trigger used by chain reactions.
func trigger() -> void:
	explode()

func explode() -> void:
	if _exploded:
		return
	_exploded = true
	if level_manager == null or bomb_rules == null:
		queue_free()
		return
	var origin := level_manager.position_to_cell(global_position)
	for direction in BombCollisionHandler.DIRECTIONS:
		var affected := bomb_rules.propagate_explosion(origin, direction, bomb_radius)
		if affected.is_empty():
			continue
		_spawn_explosion_visual(origin, direction, affected.size())
		for cell in affected:
			_damage_enemies_in_cell(cell)
			_chain_bombs_in_cell(cell)
	exploded.emit()
	GameStateManager.add_score(POINTS_PER_BOMB)
	queue_free()

func _spawn_explosion_visual(origin: Vector2i, direction: Vector2i, length: int) -> void:
	var visual := Explosion.new()
	visual.setup(level_manager, origin, direction, length)
	if get_parent():
		get_parent().add_child(visual)

func _damage_enemies_in_cell(cell: Vector2i) -> void:
	var rect := Rect2(
		level_manager.cell_to_position(cell) - Vector2(16.0, 16.0),
		Vector2(32.0, 32.0)
	)
	for body in get_tree().get_nodes_in_group("enemies"):
		if body is Node2D and body.has_method("take_damage") and rect.has_point(body.global_position):
			body.take_damage(1.0)

func _chain_bombs_in_cell(cell: Vector2i) -> void:
	for other in get_tree().get_nodes_in_group("bombs"):
		if other == self:
			continue
		if other is Node2D and other.has_method("trigger") \
				and level_manager.position_to_cell(other.global_position) == cell:
			other.trigger()
