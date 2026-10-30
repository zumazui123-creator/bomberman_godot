## Tracer Enemy
## Fast hunter: chases the player across open rows/columns with clear
## line of sight, otherwise wanders like a crawler.

extends Area2D
class_name TracerEnemy

const SPRITE_PATH := "res://Assets/Player/Red/player_05.png"
const TINT := Color(1.0, 0.6, 0.3)
const VISION_RANGE_TILES := 8

var hp := 2
var move_speed := 95.0
var chase_speed := 120.0

var level_manager = null  # LevelManager, set by LevelManager before add_child

var _alive := true
var _current_cell := Vector2i(-1, -1)
var _target_cell := Vector2i(-1, -1)
var _facing := Vector2i.ZERO
var _moving := false
var _chasing := false
var _sprite: Sprite2D

signal died

static func create() -> TracerEnemy:
	var enemy := TracerEnemy.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20.0, 20.0)
	var collision := CollisionShape2D.new()
	collision.shape = shape
	enemy.add_child(collision)
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(SPRITE_PATH):
		sprite.texture = load(SPRITE_PATH)
	sprite.scale = Vector2.ONE * 0.2
	sprite.modulate = TINT
	enemy.add_child(sprite)
	enemy._sprite = sprite
	return enemy

func _ready() -> void:
	add_to_group("enemies")
	if level_manager:
		_current_cell = level_manager.position_to_cell(global_position)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not _alive or level_manager == null:
		return
	if not GameStateManager.is_playing():
		return
	if not _moving:
		_choose_next_direction()
		return
	var speed := chase_speed if _chasing else move_speed
	var target_pos: Vector2 = level_manager.cell_to_position(_target_cell)
	var to_target := target_pos - global_position
	var step := speed * delta
	if to_target.length() <= step:
		global_position = target_pos
		_current_cell = _target_cell
		_moving = false
		_chasing = false
	else:
		global_position += to_target.normalized() * step

func is_alive() -> bool:
	return _alive

func _choose_next_direction() -> void:
	var dir := _pick_direction()
	if dir == Vector2i.ZERO:
		return
	_facing = dir
	_target_cell = _current_cell + dir
	_moving = true

func _pick_direction() -> Vector2i:
	var chase := _chase_direction()
	if chase != Vector2i.ZERO:
		_chasing = true
		return chase
	_chasing = false
	return _pick_random_walkable()

## Returns the direction to step toward the player when there is a clear
## straight line (same row or column, within vision range).
func _chase_direction() -> Vector2i:
	var player := _get_player()
	if player == null:
		return Vector2i.ZERO
	var delta: Vector2i = level_manager.position_to_cell(player.global_position) - _current_cell
	if absi(delta.x) + absi(delta.y) > VISION_RANGE_TILES:
		return Vector2i.ZERO
	if delta.x == 0 and delta.y != 0:
		var dir := Vector2i.DOWN if delta.y > 0 else Vector2i.UP
		if _path_clear(dir, absi(delta.y)):
			return dir
	elif delta.y == 0 and delta.x != 0:
		var dir := Vector2i.RIGHT if delta.x > 0 else Vector2i.LEFT
		if _path_clear(dir, absi(delta.x)):
			return dir
	return Vector2i.ZERO

func _path_clear(direction: Vector2i, distance: int) -> bool:
	var cell := _current_cell
	for i in range(distance):
		cell += direction
		if level_manager.is_solid_cell(cell):
			return false
	return true

func _pick_random_walkable() -> Vector2i:
	var options: Array[Vector2i] = []
	for dir in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		if level_manager.is_walkable_cell(_current_cell + dir):
			options.append(dir)
	if options.is_empty():
		return Vector2i.ZERO
	if options.size() > 1 and _facing != Vector2i.ZERO:
		var without_reverse: Array[Vector2i] = []
		for dir in options:
			if dir != -_facing:
				without_reverse.append(dir)
		if not without_reverse.is_empty():
			options = without_reverse
	return options[randi() % options.size()]

func _get_player() -> Node2D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null

func take_damage(amount: float = 1.0) -> void:
	if not _alive:
		return
	hp -= int(amount)
	if hp <= 0:
		_die()
		return
	modulate.a = 0.55
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.25)

func _die() -> void:
	_alive = false
	GameStateManager.add_score(100)
	died.emit()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(0.2, 0.2), 0.3)
	tween.tween_callback(queue_free)

func _on_body_entered(body: Node2D) -> void:
	if _alive and body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1.0, self)
