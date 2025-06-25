extends Node
# Main.gd
# Script principal do jogo, gerencia a UI, a navegação entre salas e a interação.
extends Node2D

# --- Nós da UI (conectados via @onready) ---
@onready var start_screen = $StartScreen
@onready var start_game_button = $StartScreen/StartGameButton
@onready var game_interface = $GameInterface
@onready var money_display = $GameInterface/PanelContainer/VBoxContainer/HBoxContainer/MoneyLabel
@onready var caught_count_display = $GameInterface/PanelContainer/VBoxContainer/HBoxContainer/CaughtCountLabel
@onready var max_caught_display = $GameInterface/PanelContainer/VBoxContainer/HBoxContainer/MaxCaughtLabel
@onready var game_message_label = $GameInterface/PanelContainer/VBoxContainer/GameMessage
@onready var room_title_label = $GameInterface/PanelContainer2/VBoxContainer/RoomTitle
@onready var family_alert_label = $GameInterface/PanelContainer2/VBoxContainer/FamilyAlert
@onready var item_actions_container = $GameInterface/PanelContainer2/VBoxContainer/ItemActions
@onready var navigation_buttons_container = $GameInterface/PanelContainer3/VBoxContainer/NavigationButtons
@onready var qte_overlay = $QTEOverlay # Instância da cena QTEOverlay.tscn
@onready var game_over_screen = $GameOverScreen
@onready var game_over_message_label = $GameOverScreen/GameOverMessage
@onready var restart_game_button = $GameOverScreen/RestartGameButton
@onready var family_move_timer = $GameInterface/FamilyMoveTimer

# --- Variáveis Internas do Jogo ---
var current_room_key = "livingRoom" # Chave da sala atual do jogador
var qte_target_item_key = ""      # Guarda a chave do item clicado antes de um QTE

# --- Funções Iniciais (Godot Lifecycle) ---

# Chamado quando o nó e seus filhos estão prontos.
func _ready():
    # Conecta os botões da tela inicial/game over
    start_game_button.pressed.connect(start_game)
    restart_game_button.pressed.connect(start_game)

    # Conecta os sinais do GameManager (Singleton) para atualizar a UI
    GameManager.money_changed.connect(_on_money_changed)
    GameManager.caught_changed.connect(_on_caught_changed)
    GameManager.game_message_changed.connect(_on_game_message_changed)
    GameManager.game_over_status_changed.connect(_on_game_over_status_changed)
    GameManager.qte_active_changed.connect(_on_qte_active_changed)
    GameManager.family_location_changed.connect(_on_family_location_changed)
    GameManager.game_reset.connect(_on_game_reset) # Conecta ao sinal de reset do GameManager

    # Conecta o sinal de resultado do QTE
    qte_overlay.qte_result.connect(_on_qte_result)

    # Conecta o timer de movimentação da família
    family_move_timer.timeout.connect(_on_family_move_timer_timeout)
    family_move_timer.wait_time = GameManager.family_move_interval # Define o tempo de espera do timer

    update_ui() # Atualiza a UI inicialmente com o estado do GameManager

# --- Funções do Jogo ---

# Inicia ou reinicia o jogo.
func start_game():
    GameManager.reset_game_state() # Reseta o estado global
    current_room_key = "livingRoom" # Redefine a sala do jogador
    qte_target_item_key = ""
    
    start_screen.visible = false
    game_interface.visible = true
    game_over_screen.visible = false
    qte_overlay.visible = false # Garante que o QTE esteja escondido
    
    # Inicia o timer da família e o processo de UI
    family_move_timer.start()
    set_process_input(true) # Habilita _input para lidar com interações
    
    update_ui() # Atualiza a UI após o reset

# Navega o jogador para uma nova sala.
func move_to_room(new_room_key: String):
    if GameManager.is_game_over or GameManager.is_qte_active: return

    if GameManager.rooms[current_room_key].exits.has(new_room_key):
        current_room_key = new_room_key
        # Atualiza a mensagem e a detecção de família
        GameManager.game_message = "Você está na %s." % GameManager.rooms[current_room_key].name
        update_family_detection()
        update_ui()
    else:
        GameManager.game_message = "Você não pode ir para lá daqui."
        update_ui()

# Lida com a interação do jogador com um item na sala.
func interact_with_item(item_key: String):
    if GameManager.is_game_over or GameManager.is_qte_active: return

    var item = GameManager.rooms[current_room_key].items[item_key]
    if item.found:
        GameManager.game_message = "Você já pegou o que tinha no %s." % item.name
        update_ui()
        return

    GameManager.game_message = "Você está investigando o %s..." % item.name
    update_ui()

    if is_family_detected():
        # Armazena qual item está sendo procurado para depois do QTE
        qte_target_item_key = item_key 
        qte_overlay.start_qte() # Inicia o QTE
    else:
        # Se não houver família, adiciona dinheiro diretamente
        GameManager.add_money(item.value)
        GameManager.rooms[current_room_key].items[item_key].found = true
        GameManager.game_message = "Você encontrou $%s no %s! Total: $%s" % [item.value, item.name, GameManager.money]
        update_ui()

# Verifica se a família está na mesma sala que o jogador.
func is_family_detected() -> bool:
    return GameManager.family_location == current_room_key

# Atualiza o estado de detecção da família para a UI e a mensagem do jogo.
func update_family_detection():
    family_alert_label.visible = is_family_detected()
    if is_family_detected() and not GameManager.is_game_over:
        GameManager.game_message = "Cuidado! Alguém da família está aqui!"
    else:
        # Se a família não está na sala e não há outra mensagem urgente, defina uma padrão.
        if GameManager.game_message.begins_with("Você está na") or GameManager.game_message.begins_with("Cuidado!"):
             GameManager.game_message = "Você está na %s." % GameManager.rooms[current_room_key].name
    game_message_label.text = GameManager.game_message # Atualiza a label diretamente

# Atualiza todos os elementos da UI com base no estado atual do GameManager.
func update_ui():
    money_display.text = str(GameManager.money)
    caught_count_display.text = str(GameManager.caught_count)
    max_caught_display.text = str(GameManager.max_caught)
    game_message_label.text = GameManager.game_message
    room_title_label.text = GameManager.rooms[current_room_key].name
    
    # Atualiza a visibilidade da mensagem de alerta da família
    family_alert_label.visible = is_family_detected()

    # Redesenha os botões de itens
    for child in item_actions_container.get_children():
        child.queue_free() # Remove botões antigos
    
    for item_key in GameManager.rooms[current_room_key].items:
        var item = GameManager.rooms[current_room_key].items[item_key]
        var button = Button.new()
        button.text = "%s\n%s" % [item.name, item.description]
        if item.value > 0 and not item.found:
            button.text += "\nValor: $%s" % item.value
        
        button.add_theme_font_size_override("font_size", 20) # Aumenta a fonte
        button.add_theme_constant_override("h_separation", 10) # Espaçamento horizontal
        button.add_theme_constant_override("v_separation", 10) # Espaçamento vertical

        var style_box_flat = StyleBoxFlat.new()
        style_box_flat.set_border_width_all(2)
        style_box_flat.set_border_color(Color("3b82f6")) # Cor da borda azul
        style_box_flat.set_corner_radius_all(8)
        style_box_flat.set_content_margin_all(12)

        var style_box_disabled = StyleBoxFlat.new()
        style_box_disabled.set_bg_color(Color("4b5563")) # Cinza para desabilitado
        style_box_disabled.set_border_width_all(2)
        style_box_disabled.set_border_color(Color("374151"))
        style_box_disabled.set_corner_radius_all(8)
        style_box_disabled.set_content_margin_all(12)


        if item.found:
            style_box_flat.set_bg_color(Color("2a2a2a")) # Cor mais escura para itens encontrados
            button.disabled = true
        else:
            style_box_flat.set_bg_color(Color("3b82f6")) # Azul para itens interativos
            button.disabled = GameManager.is_qte_active or GameManager.is_game_over
        
        button.add_theme_stylebox_override("normal", style_box_flat)
        button.add_theme_stylebox_override("disabled", style_box_disabled)
        button.pressed.connect(interact_with_item.bind(item_key))
        item_actions_container.add_child(button)

    # Redesenha os botões de navegação
    for child in navigation_buttons_container.get_children():
        child.queue_free() # Remove botões antigos

    for exit_key in GameManager.rooms[current_room_key].exits:
        var button = Button.new()
        button.text = GameManager.rooms[exit_key].name
        button.add_theme_font_size_override("font_size", 22) # Aumenta a fonte
        button.add_theme_constant_override("h_separation", 15)
        button.add_theme_constant_override("v_separation", 10)

        var style_box_nav = StyleBoxFlat.new()
        style_box_nav.set_bg_color(Color("6366f1")) # Indigo
        style_box_nav.set_corner_radius_all(9999) # Fully rounded
        style_box_nav.set_content_margin_all(15)

        var style_box_nav_disabled = StyleBoxFlat.new()
        style_box_nav_disabled.set_bg_color(Color("4b5563"))
        style_box_nav_disabled.set_corner_radius_all(9999)
        style_box_nav_disabled.set_content_margin_all(15)

        button.add_theme_stylebox_override("normal", style_box_nav)
        button.add_theme_stylebox_override("disabled", style_box_nav_disabled)

        button.disabled = GameManager.is_qte_active or GameManager.is_game_over
        button.pressed.connect(move_to_room.bind(exit_key))
        navigation_buttons_container.add_child(button)

# --- Conexão de Sinais do GameManager ---

func _on_money_changed(new_money: int):
    money_display.text = str(new_money)

func _on_caught_changed(new_caught_count: int):
    caught_count_display.text = str(new_caught_count)

func _on_game_message_changed(message: String):
    game_message_label.text = message

func _on_game_over_status_changed(is_over: bool):
    game_over_screen.visible = is_over
    game_interface.visible = not is_over # Esconde a interface do jogo quando Game Over

    if is_over:
        game_over_message_label.text = GameManager.game_message
        family_move_timer.stop() # Para o timer da família
        set_process_input(false) # Desabilita input para evitar interações acidentais

func _on_qte_active_changed(active_state: bool):
    # A visibilidade do QTEOverlay é gerenciada pelo próprio script QTEOverlay.gd
    # Este sinal serve para desabilitar/habilitar outros botões da UI.
    update_ui() # Chama update_ui para atualizar os estados disabled dos botões

func _on_family_location_changed(new_location_key: String):
    # Não precisa fazer nada aqui diretamente, `update_family_detection`
    # e `update_ui` já cuidam de atualizar a visualização e mensagem.
    update_family_detection() # Atualiza o alerta na UI

func _on_game_reset():
    # Reinicia a UI para refletir o estado limpo do GameManager
    update_ui()
    family_move_timer.start() # Reinicia o timer da família após o reset

# --- Conexão do Timer de Movimentação da Família ---

func _on_family_move_timer_timeout():
    if GameManager.is_game_over or GameManager.is_qte_active: return

    var room_keys = GameManager.rooms.keys()
    var new_family_location_key: String
    
    # Garante que a família não se mova para a sala atual do jogador
    do:
        new_family_location_key = room_keys[randi() % room_keys.size()]
    while new_family_location_key == current_room_key

    GameManager.set_family_location(new_family_location_key)
    update_family_detection() # Atualiza o alerta de detecção na UI

# --- Conexão do Sinal de Resultado do QTE ---

func _on_qte_result(success: bool):

    if success:
        GameManager.game_message = "Ufa! Você escapou por pouco!"
        # Adiciona dinheiro do item que estava sendo procurado antes do QTE
        if not qte_target_item_key.is_empty() and not GameManager.rooms[current_room_key].items[qte_target_item_key].found:
            var item = GameManager.rooms[current_room_key].items[qte_target_item_key]
            GameManager.add_money(item.value)
            GameManager.rooms[current_room_key].items[qte_target_item_key].found = true
            GameManager.game_message += " Você encontrou $%s no %s! Total: $%s" % [item.value, item.name, GameManager.money]
        qte_target_item_key = "" # Reseta a chave do item alvo
    else:
        GameManager.game_message = "Você falhou! Foi pego!"
        GameManager.increment_caught()
    
    update_ui() # Atualiza a UI para refletir o resultado do QTE

