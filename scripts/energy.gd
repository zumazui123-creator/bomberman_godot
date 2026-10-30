## Energy Item / Power-up Drop
## Spawns from destroyed bricks. Picked up by the player on contact.
##  - ENERGY: bonus score
##  - BOMB:   one extra simultaneous bomb
##  - FIRE:   one extra explosion range

class_name EnergyItem
extends Area2D

enum ItemType { ENERGY, BOMB, FIRE }

const SPRITES := {
	ItemType.ENERGY: "res://Assets/Items/item_random.png",
	ItemType.BOMB: "res://Assets/Items/item_bomb.png",
	ItemType.FIRE: "res://Assets/Items/item_nuke.png",
}

var item_type: ItemType = ItemType.ENERGY
var power_up_manager: PowerUpManager = null

signal picked_up(item_type: ItemType)

static func create(p_type: ItemType) -> EnergyItem:
	var item := EnergyItem.new()
	item.item_type = p_type
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	item.add_child(collision)
	var sprite := Sprite2D.new()
	if ResourceLoader.exists(SPRITES[p_type]):
		sprite.texture = load(SPRITES[p_type])
	else:
		sprite.texture = _make_fallback_texture(p_type)
	sprite.scale = Vector2.ONE * 0.2
	item.add_child(sprite)
	item._sprite_node = sprite
	return item

static func _make_fallback_texture(p_type: ItemType) -> Texture2D:
	# Procedural 16x16 colored square if the Kenney item art is missing.
	var color := Color(1.0, 0.9, 0.3)
	match p_type:
		ItemType.BOMB:
			color = Color(0.3, 0.3, 0.3)
		ItemType.FIRE:
			color = Color(1.0, 0.45, 0.1)
	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var border := x == 0 or y == 0 or x == 15 or y == 15
			image.set_pixel(x, y, color.darkened(0.4) if border else color)
	return ImageTexture.create_from_image(image)

var _sprite_node: Sprite2D = null

func _ready() -> void:
	add_to_group("items")
	body_entered.connect(_on_body_entered)

func _process(_delta: float) -> void:
	if _sprite_node:
		_sprite_node.rotation += _delta * 2.0

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	match item_type:
		ItemType.ENERGY:
			GameStateManager.add_score(50)
		ItemType.BOMB:
			if power_up_manager:
				power_up_manager.apply_bomb_upgrade()
		ItemType.FIRE:
			if power_up_manager:
				power_up_manager.apply_fire_upgrade()
	picked_up.emit(item_type)
	queue_free()
