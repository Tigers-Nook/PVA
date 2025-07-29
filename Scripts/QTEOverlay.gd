# QTEOverlay.gd
# Gerencia a lógica e a UI do Quick Time Event (QTE).
extends Control

# --- Nós da UI (conectados via @onready) ---
@onready var key_display = $ColorRect/QTEBox/VBoxContainer/QTEKeyDisplay
@onready var progress_bar = $ColorRect/QTEBox/VBoxContainer/QTEProgressBar
@onready var timer_text = $ColorRect/QTEBox/VBoxContainer/QTETimerText

# --- Variáveis Internas do QTE ---
var current_qte_key = "" # A tecla que o jogador deve pressionar
var qte_timer_node = Timer.new() # Um nó Timer para a contagem regressiva do QTE

# --- Sinal para a cena principal ---
signal qte_result(success: bool) # Emite true para sucesso, false para falha

# --- Funções Iniciais (Godot Lifecycle) ---

# Chamado quando o nó QTEOverlay está pronto.
func _ready():
	add_child(qte_timer_node) # Adiciona o Timer como filho deste nó
	qte_timer_node.wait_time = GameManager.qte_duration # Define a duração do QTE
	qte_timer_node.one_shot = true # O Timer dispara apenas uma vez
	qte_timer_node.timeout.connect(_on_qte_timeout) # Conecta o sinal timeout do Timer

	# Configura os estilos dos elementos (opcional, pode ser feito no editor)
	# Exemplo para a barra de progresso
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color("10b981") # Cor verde
	progress_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("fill", progress_style)

	var background_style = StyleBoxFlat.new()
	background_style.bg_color = Color("9ca3af") # Cinza para o fundo da barra
	background_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("background", background_style)

	# Configura o estilo do painel QTEBox
	var qte_box_style = StyleBoxFlat.new()
	qte_box_style.bg_color = Color("fcd34d") # Amarelo
	qte_box_style.set_border_width_all(5)
	qte_box_style.set_border_color(Color("fbbf24")) # Amarelo escuro
	qte_box_style.set_corner_radius_all(15)
	$ColorRect/QTEBox.add_theme_stylebox_override("panel", qte_box_style)

	# Configura a fonte para o QTEKeyDisplay
	var font_data = preload("res://Assets/Fonts/Roboto-Bold.ttf") # Exemplo, ajuste o caminho da sua fonte
	var dynamic_font = FontFile.new()
	dynamic_font.font_data = font_data
	dynamic_font.size = 100 # Ajuste o tamanho da fonte conforme necessário
	key_display.add_theme_font_override("font", dynamic_font)
	key_display.add_theme_color_override("font_color", Color("dc2626")) # Cor vermelha
	key_display.add_theme_constant_override("shadow_offset_x", 3)
	key_display.add_theme_constant_override("shadow_offset_y", 3)
	key_display.add_theme_color_override("font_shadow_color", Color("000000", 0.3))

	# Configura a fonte para QTE title e timer text
	var label_font = FontFile.new()
	label_font.font_data = font_data
	label_font.size = 30
	$ColorRect/QTEBox/VBoxContainer/Label.add_theme_font_override("font", label_font)
	$ColorRect/QTEBox/VBoxContainer/Label.add_theme_color_override("font_color", Color("1f2937"))
	
	var timer_font = FontFile.new()
	timer_font.font_data = font_data
	timer_font.size = 20
	timer_text.add_theme_font_override("font", timer_font)
	timer_text.add_theme_color_override("font_color", Color("1f2937"))

# Chamado a cada frame para atualizar a barra de progresso e o texto do timer.
func _process(delta: float):
	# Calcula o valor da barra de progresso com base no tempo restante
	if qte_timer_node.time_left > 0:
		progress_bar.value = (qte_timer_node.time_left / GameManager.qte_duration) * 100
		timer_text.text = "Tempo restante: %.1fs" % qte_timer_node.time_left
	else:
		progress_bar.value = 0
		timer_text.text = "Tempo restante: 0.0s"
		set_process(false) # Desabilita _process quando o tempo acaba

# Lida com a entrada do usuário (teclas pressionadas).
func _unhandled_input(event: InputEvent):
	if visible and event is InputEventKey and event.pressed:
		if event.as_text().to_upper() == current_qte_key:
			end_qte(true) # Sucesso no QTE
			get_viewport().set_input_as_handled() # Consome o evento para não ser processado por outros nós
		else:
			end_qte(false) # Falha no QTE (tecla errada)
			get_viewport().set_input_as_handled()

# --- Funções do QTE ---

# Inicia o QTE.
func start_qte():
	visible = true # Torna o overlay visível
	GameManager.set_qte_active(true) # Atualiza o estado global
	
	var possible_keys = ["A", "S", "D", "F", "J", "K", "L", "C"] # Teclas possíveis para o QTE
	current_qte_key = possible_keys[randi() % possible_keys.size()] # Seleciona uma tecla aleatoriamente
	key_display.text = current_qte_key # Exibe a tecla na UI

	progress_bar.value = 100 # Inicia a barra de progresso cheia
	qte_timer_node.start() # Inicia o Timer
	set_process(true) # Habilita _process para que a barra de progresso se atualize

# Finaliza o QTE e emite o resultado.
func end_qte(success: bool):
	if not visible: return # Evita múltiplas chamadas se já estiver invisível

	visible = false # Esconde o overlay
	GameManager.set_qte_active(false) # Atualiza o estado global
	
	qte_result.emit(success) # Emite o sinal de resultado para a cena principal
	set_process(false) # Desabilita _process para economizar recursos

# Chamado quando o Timer do QTE se esgota.
func _on_qte_timeout():
	end_qte(false) # QTE falhou por tempo esgotado
