## Audio Manager
## Sound effects, music, ambient sounds
## 🔊 AUDIO SYSTEM! 🎵

extends Node2D
class_name AudioManager

# Sound categories
var bomb_sound := AudioStreamSample.new()
var explosion_sound := AudioStreamSample.new()
var player_step_sound := AudioStreamSample.new()
var enemy_damage_sound := AudioStreamSample.new()
var powerup_pickup_sound := AudioStreamSample.new()
var game_over_music := AudioStreamPlayer.new()
var victory_music := AudioStreamPlayer.new()

# Volume settings
const PLAYER_VOLUME = 0.5
const AMBIENT_VOLUME = 0.3
const EFFECT_VOLUME = 1.0
const MUSIC_VOLUME = 0.4

signal sound_played(sound_name: String)

func _ready() -> void:
	print("🔊 AudioManager initialized!")
	# Create temp audio nodes for testing
	add_audio_node("player_step", "res://assets/audio/step.wav", EFFECT_VOLUME)
	add_audio_node("explosion", "res://assets/audio/explosion.wav", EFFECT_VOLUME)
	add_audio_node("powerup", "res://assets/audio/powerup.wav", EFFECT_VOLUME)
	
	# Add music
	add_music_node("game_over")
	add_music_node("victory")

# Add audio sample
func add_audio_node(name: String, path: String, volume: float = EFFECT_VOLUME) -> void:
	var player = AudioStreamPlayer.new()
	player.bus = "SFX"
	player.volume_db = volume
	player.stream = AudioStreamSample.new()
	add_child(player)
	
	# Store reference
	if not has_symbol("{}".format(name)):
		set(get_name() + "{}_player".format(name), player)
		sound_played.emit(name)

# Play audio sample
func play_samples(name: String) -> void:
	var symbol = get_symbol("{}_player".format(name))
	if symbol:
		symbol.play()

# Play explosion sound
func play_explosion_sound() -> void:
	sound_played.emit("explosion")
	# TODO: Add actual sound

# Play powerup sound
func play_powerup_sound() -> void:
	sound_played.emit("powerup")
	# TODO: Add actual sound

# Play player step sound
func play_player_step_sound() -> void:
	sound_played.emit("player_step")
	# TODO: Add actual sound

# Play music
func play_music(music_name: String) -> void:
	var symbol = get_symbol("{}_player".format(name))
	if symbol:
		symbol.play()

func add_music_node(music_name: String) -> void:
	var player = AudioStreamPlayer.new()
	add_child(player)

# Reset audio
func reset_audio() -> void:
	pass