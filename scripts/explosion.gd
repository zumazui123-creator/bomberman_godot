## Explosion Visual
## Pure visual effect: plays the Kenney explosion frames along the
## direction, stretched for the blast length, then fades out.
## All gameplay logic (tile destruction, damage) lives in the bomb.

extends Node2D
class_name Explosion

const FRAME_DIR := "res://Assets/Explosions/simpleExplosion%02d.png"
const FRAME_COUNT := 9
const LIFETIME := 0.45
const TILE_SIZE := 32.0

var level_manager: LevelManager = null

var _origin := Vector2i.ZERO
var _direction := Vector2i.RIGHT
var _length := 1
var _frames: Array[Texture2D] = []
var _timer := 0.0
var _sprite: Sprite2D

func setup(p_level_manager: LevelManager, origin: Vector2i, direction: Vector2i, length: int) -> void:
	level_manager = p_level_manager
	_origin = origin
	_direction = direction
	_length = maxi(length, 1)

func _ready() -> void:
	for i in range(FRAME_COUNT):
		var path := FRAME_DIR % i
		if ResourceLoader.exists(path):
			_frames.append(load(path))
	_sprite = Sprite2D.new()
	if _frames.is_empty():
		_sprite.texture = _make_fallback_texture()
		_sprite.scale = Vector2.ONE * 0.9
	else:
		_sprite.texture = _frames[0]
		var scale := TILE_SIZE / _frames[0].get_size().x
		# Stretch along the blast direction (sprite's local X axis).
		_sprite.scale = Vector2(1.0 + (_length - 1) * 0.85, 1.0) * scale
	_sprite.rotation = _rotation_for_direction()
	add_child(_sprite)
	if level_manager:
		global_position = level_manager.cell_to_position(_origin + _direction)

func _rotation_for_direction() -> float:
	match _direction:
		Vector2i.RIGHT:
			return 0.0
		Vector2i.DOWN:
			return PI / 2.0
		Vector2i.LEFT:
			return PI
		_:
			return -PI / 2.0

static func _make_fallback_texture() -> Texture2D:
	var image := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	for y in range(32):
		for x in range(32):
			var d := Vector2(x - 15.5, y - 15.5).length()
			if d < 14.0:
				image.set_pixel(x, y, Color(1.0, 0.55, 0.1).lerp(Color(1.0, 0.95, 0.4), 1.0 - d / 14.0))
			else:
				image.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0))
	return ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	_timer += delta
	if _timer >= LIFETIME:
		queue_free()
		return
	var progress := _timer / LIFETIME
	if not _sprite:
		return
	if not _frames.is_empty():
		var index := int(progress * float(_frames.size()))
		_sprite.texture = _frames[mini(index, _frames.size() - 1)]
	# Fade out over the final third.
	_sprite.modulate.a = 1.0 if progress < 0.6 else (1.0 - (progress - 0.6) / 0.4)
