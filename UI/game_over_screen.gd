extends Control

@onready var restart_btn = $RestartGameButton
@onready var main_menu_btn = $MainMenuBtn
func _ready():
	restart_btn.pressed.connect(restart_game)
	main_menu_btn.pressed.connect(main_menu)

func restart_game() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
	print("Jogo reiniciado!")

func main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
	
