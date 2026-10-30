## Audio Manager (Autoload: AudioManager)
## Music playback + SFX hook. SFX asset paths can be registered at runtime;
## calls for unknown SFX names are safe no-ops (silent), so the game works
## even before sound assets are added.

extends Node

const MUSIC_PATH := "res://Assets/Music/gametrack1.ogg"
const MUSIC_VOLUME_DB := -8.0

signal sound_played(sound_name: String)

var music_player: AudioStreamPlayer
var sfx_streams: Dictionary = {}

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = MUSIC_VOLUME_DB
	add_child(music_player)
	if ResourceLoader.exists(MUSIC_PATH):
		music_player.stream = load(MUSIC_PATH)
		music_player.play()
	else:
		push_warning("AudioManager: music asset not found at %s" % MUSIC_PATH)

func register_sfx(sound_name: String, stream_path: String) -> void:
	if ResourceLoader.exists(stream_path):
		sfx_streams[sound_name] = load(stream_path)
	else:
		push_warning("AudioManager: SFX asset not found at %s" % stream_path)

func play_sfx(sound_name: String) -> void:
	if not sfx_streams.has(sound_name):
		return
	var player := AudioStreamPlayer.new()
	player.stream = sfx_streams[sound_name]
	add_child(player)
	player.play()
	sound_played.emit(sound_name)
	player.finished.connect(player.queue_free)

func stop_music() -> void:
	if music_player:
		music_player.stop()

func play_music() -> void:
	if music_player and music_player.stream:
		music_player.play()
