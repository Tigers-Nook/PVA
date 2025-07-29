# MusicManager.gd
extends Node

# Pré-carrega as faixas de música para evitar engasgos.
var menu_track = preload("res://audio/menu_music.mp3")
var gameplay_track = preload("res://audio/gameplay_music.mp3")

func _ready():
	# Garante que o player de áudio continue tocando entre as cenas.
	process_mode = Node.PROCESS_MODE_ALWAYS

func play_menu_music():
	$AudioStreamPlayer.stream = menu_track
	$AudioStreamPlayer.play()

func play_gameplay_music():
	$AudioStreamPlayer.stream = gameplay_track
	$AudioStreamPlayer.play()

func stop_music():
	$AudioStreamPlayer.stop()
