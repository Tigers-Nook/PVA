extends Control

# Menu.gd
# Este script gerencia o menu principal do jogo, incluindo a navegação entre as opções e
# a interação com o botão de "Iniciar Jogo" e "Fechar Jogo".

func _ready():
	# Conecta o sinal de clique do botão "Iniciar Jogo" para a função start_game
	$StartGameButton.pressed.connect(start_game)
	$QuitButton.pressed.connect(quit_game)
	#MusicManager.play_menu_music()
	
func start_game() -> void:
	# Inicia o jogo ao pressionar o botão "Iniciar Jogo"
	GameManager.reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")  # Altere o caminho para o seu GameManager.tscn
	
	# Aqui você pode adicionar lógica adicional para inicializar o jogo, se necessário
	print("Jogo iniciado!")  # Mensagem de depuração para confirmar que o jogo foi iniciado
	# Você pode também emitir um sinal ou chamar uma função no GameManager para iniciar o jogo, se necessário
	# Exemplo:
	# GameManager.get_instance().initialize_game()  # Se você tiver uma função de inicialização no GameManager
	
func quit_game() -> void:
	get_tree().quit()


# Certifique-se de que o caminho para o GameManager.tscn esteja correto e que o botão "Iniciar Jogo" esteja configurado corretamente na cena do menu.
# Este script deve ser anexado a um nó Control na cena do menu principal, e o botão "Iniciar Jogo" deve ser um filho desse nó Control.
# Você pode personalizar a lógica de inicialização do jogo conforme necessário, dependendo de como você deseja que o jogo comece.
# Além disso, você pode adicionar mais funcionalidades ao menu, como opções de configuração, créditos, etc., conforme necessário.
# Certifique-se de que o botão "Iniciar Jogo" esteja configurado corretamente na cena do menu principal e que o caminho para o GameManager.tscn esteja correto.
# Você pode adicionar mais funcionalidades ao menu, como opções de configuração, créditos, etc., conforme necessário.             
