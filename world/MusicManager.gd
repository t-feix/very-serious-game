extends Node

var _music_started: bool = false

func on_level_loaded(level) -> void:
	print("[music] on_level_loaded called with: ", level.name)
	print("[music] _music_started: ", _music_started)
	print("[music] MusicLoop.playing: ", $MusicLoop.playing)
	if not _music_started and level.name == "Tutorial":
		_music_started = true
		$MusicIntro.play()
		$MusicIntro.finished.connect(_on_music_intro_finished)
		return
	
	if $MusicLoop.playing:
		_set_volumes(level)

func _on_music_intro_finished() -> void:
	$MusicLoop.play()
	_set_volumes_by_name("Tutorial")

func _set_volumes(level) -> void:
	_set_volumes_by_name(level.name)

func _set_volumes_by_name(level_name: String) -> void:
	var num_streams = $MusicLoop.stream.get_stream_count()
	
	for i in range(num_streams):
		$MusicLoop.stream.set_sync_stream_volume(i, -60.0)
	
	match level_name:
		"Tutorial":
			$MusicLoop.stream.set_sync_stream_volume(0, -10.0)
		"World2":
			$MusicLoop.stream.set_sync_stream_volume(1, -10.0)
		"World3":
			$MusicLoop.stream.set_sync_stream_volume(2, -10.0)


func stop_music() -> void:
	$MusicLoop.stop()
