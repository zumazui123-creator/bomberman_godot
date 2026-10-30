extends Node
## Headless smoke test for the live game runtime.
## Enabled via the SmokeTest autoload in project.godot (temporarily while testing):
##   godot --headless --path . --quit-after 900
## Quits with exit code = number of failures (0 = all passed).

var _failures := 0
var _frames := 0
var _started := false
var _post_open: Dictionary = {}

func _check(cond: bool, label: String) -> void:
	if cond:
		print("PASS: ", label)
	else:
		_failures += 1
		print("FAIL: ", label)

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 240 and not _started:
		_started = true
		_finish()
	elif _frames == 360 and _started:
		_check_movement()

func _main() -> Node:
	return get_tree().root.get_node_or_null("Main")

func _finish() -> void:
	var main := _main()
	_check(main != null, "Main scene node exists")
	if main == null:
		_quit()
		return
	var lm: LevelManager = main.get("level_manager")
	_check(lm != null and lm.current_level_index == 0, "level 0 loaded at start")
	_check(GameStateManager.current_state == GameStateManager.GameState.PLAYING,
		"game state is PLAYING")
	var player: Node2D = main.get("player")
	_check(player != null and is_instance_valid(player), "player exists")
	_check(lm.is_walkable_cell(lm.position_to_cell(player.global_position)),
		"player standing on walkable cell")

	# Border must be fully solid (no walking off the map)
	var boundary_ok := true
	for x in lm.map_size.x:
		if not lm.is_solid_cell(Vector2i(x, 0)) or not lm.is_solid_cell(Vector2i(x, lm.map_size.y - 1)):
			boundary_ok = false
	for y in lm.map_size.y:
		if not lm.is_solid_cell(Vector2i(0, y)) or not lm.is_solid_cell(Vector2i(lm.map_size.x - 1, y)):
			boundary_ok = false
	_check(boundary_ok, "level 0 border fully solid")

	# Enemies spawned (initial level)
	var alive0 := lm.get_alive_enemies()
	_check(alive0.size() == 2, "2 enemies spawned (got %d)" % alive0.size())

	# All levels load; then reload level 0 for the bomb test
	for i in range(1, lm.level_count()):
		_check(lm.load_level(i), "load_level(%d) ok" % i)
	_check(lm.load_level(0), "reload level 0 for bomb test")

	# clear_tile removes the physics body
	var brick := Vector2i.ZERO
	var found := false
	for y in lm.map_size.y:
		for x in lm.map_size.x:
			if lm.is_brick_cell(Vector2i(x, y)):
				brick = Vector2i(x, y)
				found = true
				break
		if found:
			break
	_check(found, "brick exists on level 0")
	lm.clear_tile(brick)
	_check(not lm.is_solid_cell(brick), "clear_tile removes solid body")

	# Live bomb propagation via the running collision manager
	var bomb_cell := Vector2i.ZERO
	var dir_b := Vector2i.ZERO
	var ok := false
	for y in lm.map_size.y:
		for x in lm.map_size.x:
			var c := Vector2i(x, y)
			if lm.is_brick_cell(c):
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var o: Vector2i = c - d
					if lm.is_walkable_cell(o):
						bomb_cell = o
						dir_b = d
						ok = true
						break
				if ok:
					break
		if ok:
			break
	_check(ok, "found bomb placement next to a brick")
	if ok:
		var rules: BombCollisionHandler = main.get("bomb_rules")
		var affected := rules.propagate_explosion(bomb_cell, dir_b, 3)
		_check(affected.size() >= 1, "blast affects >=1 cell (got %d)" % affected.size())
		_check(not lm.is_brick_cell(bomb_cell + dir_b), "blast destroys brick in path")

	# Power-up item: create + instantiate (exercises EnergyItem.create/_ready)
	var item: EnergyItem = EnergyItem.create(EnergyItem.ItemType.BOMB)
	_check(item != null, "EnergyItem.create returns instance")
	if item:
		main.add_child(item)
		_check(is_instance_valid(item) and item.is_inside_tree(), "item instantiated in scene tree")
		await get_tree().process_frame
		_check(item._sprite_node != null and item._sprite_node.texture != null,
			"item has texture")
		item.queue_free()

	# Enemy AI: corridor cells are boxed by pillars/bricks, so open a corridor
	# first (classic Bomberman: enemies move through destroyed-brick gaps),
	# then verify the enemy actually walks on the next check frame.
	var alive := lm.get_alive_enemies()
	if alive.size() > 0:
		var e: Node2D = alive[0]
		var e_cell: Vector2i = lm.position_to_cell(e.global_position)
		var opened := 0
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = e_cell + d
			if lm.is_brick_cell(n):
				lm.clear_tile(n)
				opened += 1
		_check(opened >= 1, "opened corridor next to enemy (%d bricks)" % opened)
		_post_open[e] = e.global_position
	else:
		_check(false, "enemy available for movement check")

func _check_movement() -> void:
	var moved_any := false
	for e in _post_open:
		if is_instance_valid(e) and _post_open[e] != e.global_position:
			moved_any = true
	_check(moved_any, "enemy moved after corridor opened (AI active)")
	print("")
	if _failures == 0:
		print("ALL SMOKE TESTS PASSED")
	else:
		print("SMOKE TEST FAILURES: %d" % _failures)
	_quit()

func _quit() -> void:
	get_tree().quit(_failures)
