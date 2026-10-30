## UI Manager
## HUD (score / lives / time / level) plus the overlay for pause,
## game over and victory screens.

extends CanvasLayer
class_name UIManager

const FONT_PATH := "res://Assets/Kenney Bold.ttf"

var score_label: Label
var lives_label: Label
var level_label: Label
var time_label: Label
var overlay: ColorRect
var overlay_title: Label
var overlay_message: Label

func _ready() -> void:
	_build_hud()
	_build_overlay()
	GameStateManager.score_changed.connect(_on_score_changed)
	GameStateManager.lives_changed.connect(_on_lives_changed)
	GameStateManager.state_changed.connect(_on_state_changed)
	_update_hud()

func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH))
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(1.0, 1.0, 0.9)
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label

func _build_hud() -> void:
	score_label = _make_label("Score: 0")
	score_label.position = Vector2(16, 12)
	add_child(score_label)
	lives_label = _make_label("Lives: 3")
	lives_label.position = Vector2(200, 12)
	add_child(lives_label)
	level_label = _make_label("Level: 1")
	level_label.position = Vector2(360, 12)
	add_child(level_label)
	time_label = _make_label("Time: 120")
	time_label.position = Vector2(520, 12)
	add_child(time_label)

func _build_overlay() -> void:
	overlay = ColorRect.new()
	overlay.color = Color(0.05, 0.05, 0.1, 0.72)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.hide()
	add_child(overlay)
	overlay_title = _make_label("")
	overlay_title.add_theme_font_size_override("font_size", 42)
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_message = _make_label("")
	overlay_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(overlay_title)
	box.add_child(overlay_message)
	overlay.add_child(box)

func _update_hud() -> void:
	score_label.text = "Score: %d" % GameStateManager.score
	lives_label.text = "Lives: %d" % GameStateManager.lives
	level_label.text = "Level: %d" % (GameStateManager.level_index + 1)
	time_label.text = "Time: 120"

func show_overlay(title: String, message: String) -> void:
	overlay_title.text = title
	overlay_message.text = message
	overlay.show()

func hide_overlay() -> void:
	overlay.hide()

func update_time(seconds: int) -> void:
	time_label.text = "Time: %d" % seconds

func update_level(level_number: int) -> void:
	level_label.text = "Level: %d" % level_number

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score

func _on_lives_changed(new_lives: int) -> void:
	lives_label.text = "Lives: %d" % new_lives

func _on_state_changed(state: int) -> void:
	match state:
		GameStateManager.GameState.PLAYING, GameStateManager.GameState.MENU:
			overlay.hide()
		GameStateManager.GameState.PAUSED:
			show_overlay("PAUSED", "Press P to resume")
		GameStateManager.GameState.GAME_OVER:
			show_overlay("GAME OVER", "Score: %d  -  Press Enter to restart" % GameStateManager.score)
		GameStateManager.GameState.VICTORY:
			show_overlay("VICTORY!", "Score: %d  -  Press Enter to play again" % GameStateManager.score)
