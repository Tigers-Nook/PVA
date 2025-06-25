extends Node
# GameManager.gd
# Este script é um singleton (Autoload) que gerencia o estado global do jogo.
extends Node

# --- Variáveis de Estado do Jogo ---
var money = 0          # Dinheiro atual do jogador
var caught_count = 0   # Quantas vezes o jogador foi pego pela família
var max_caught = 3     # Número máximo de vezes que pode ser pego antes do Game Over
var target_money = 100 # Dinheiro necessário para alcançar a "vitória" satírica

var game_message = "Você perdeu tudo nas apostas. Precisa de mais dinheiro!" # Mensagens exibidas na UI
var is_game_over = false # Estado de Game Over (inclui vitória e derrota)
var is_qte_active = false # Indica se um QTE está ativo
var family_location = ""  # A sala onde o membro da família está atualmente (nome da chave da sala)

# --- Estrutura de Dados do Jogo ---
# Dicionário que descreve cada sala do jogo
var rooms = {
	"livingRoom": {
		"name": "Sala de Estar",
		"items": {
			"sofa": {"name": "Sofá", "value": 5, "found": false, "description": "Um sofá velho e empoeirado. Talvez haja algo entre as almofadas."},
			"tv": {"name": "TV", "value": 0, "found": false, "description": "A TV está ligada. Ninguém está assistindo."},
		},
		"exits": ["kitchen", "bedroom"],
	},
	"kitchen": {
		"name": "Cozinha",
		"items": {
			"cookieJar": {"name": "Pote de Biscoitos", "value": 2, "found": false, "description": "Um pote de biscoitos vazio. Que decepção."},
			"fridge": {"name": "Geladeira", "value": 0, "found": false, "description": "Cheia de sobras. Nenhuma nota de dinheiro aqui."},
		},
		"exits": ["livingRoom"],
	},
	"bedroom": {
		"name": "Quarto do Casal",
		"items": {
			"nightstand": {"name": "Mesa de Cabeceira", "value": 10, "found": false, "description": "Pode haver algum trocado aqui."},
			"wardrobe": {"name": "Guarda-roupa", "value": 0, "found": false, "description": "Cheio de roupas velhas."},
			"wifePurse": {"name": "Bolsa da Esposa", "value": 30, "found": false, "description": "A bolsa da sua esposa. Um risco alto, mas uma recompensa maior."},
		},
		"exits": ["livingRoom", "kidsRoom", "bathroom"],
	},
	"kidsRoom": {
		"name": "Quarto das Crianças",
		"items": {
			"piggyBank": {"name": "Cofre do Porquinho", "value": 20, "found": false, "description": "O cofre do porquinho das crianças. Que dilema moral..."},
			"toyBox": {"name": "Caixa de Brinquedos", "value": 0, "found": false, "description": "Brinquedos espalhados por todo lado."},
		},
		"exits": ["bedroom"],
	},
	"bathroom": {
		"name": "Banheiro",
		"items": {
			"medicineCabinet": {"name": "Armário de Remédios", "value": 0, "found": false, "description": "Apenas remédios e produtos de higiene."},
		},
		"exits": ["bedroom"],
	},
}

# --- Sinais para Observadores da UI (ex: Main Scene) ---
# Emitem eventos quando o estado do jogo muda, permitindo que a UI se atualize.
signal money_changed(new_money)
signal caught_changed(new_caught_count)
signal game_message_changed(message)
signal game_over_status_changed(game_over_state)
signal qte_active_changed(active_state)
signal family_location_changed(new_location_key) # Novo sinal para a localização da família
signal game_reset() # Sinal para indicar que o jogo foi resetado

# --- Configurações do Jogo ---
var qte_duration = 1.5   # Duração do QTE em segundos
var family_move_interval = 5.0 # Intervalo de tempo para a família se mover (em segundos)

# --- Funções do GameManager ---

# Chamado quando o nó GameManager está pronto.
func _ready():
	randomize() # Garante que as funções randi() e randf() gerem sequências diferentes a cada execução.

# Adiciona dinheiro ao total do jogador e emite o sinal correspondente.
func add_money(amount: int):
	money += amount
	money_changed.emit(money) # Notifica a UI
	check_win_condition() # Verifica se a condição de vitória foi atingida

# Incrementa a contagem de vezes que o jogador foi pego e verifica o Game Over por derrota.
func increment_caught():
	caught_count += 1
	caught_changed.emit(caught_count) # Notifica a UI
	if caught_count >= max_caught:
		set_game_over(true, "Você foi pego %s vezes! Sua família descobriu tudo. Fim de jogo." % max_caught)
	else:
		game_message = "Cuidado! Você foi pego %s de %s vezes." % [caught_count, max_caught]
		game_message_changed.emit(game_message) # Notifica a UI

# Define o estado de Game Over e a mensagem final.
func set_game_over(status: bool, message_text: String = ""):
	is_game_over = status
	if not message_text.is_empty():
		game_message = message_text
	game_over_status_changed.emit(is_game_over) # Notifica a UI
	game_message_changed.emit(game_message) # Notifica a UI

# Verifica se o jogador atingiu o dinheiro alvo para a "vitória" satírica.
func check_win_condition():
	if money >= target_money and not is_game_over:
		set_game_over(true, "Parabéns! Você conseguiu $%s para fazer outra aposta... Que vergonha!" % target_money)

# Define o estado de atividade do QTE.
func set_qte_active(status: bool):
	is_qte_active = status
	qte_active_changed.emit(status) # Notifica a UI

# Define a localização atual da família e emite o sinal.
func set_family_location(location_key: String):
	family_location = location_key
	family_location_changed.emit(location_key) # Notifica a UI

# Reseta todos os estados do jogo para o início.
func reset_game_state():
	money = 0
	caught_count = 0
	game_message = "Você perdeu tudo nas apostas. Precisa de mais dinheiro!"
	is_game_over = false
	is_qte_active = false

	# Reseta o estado 'found' de todos os itens em todas as salas
	for room_key in rooms:
		for item_key in rooms[room_key]["items"]:
			rooms[room_key]["items"][item_key]["found"] = false

	# Randomiza a localização inicial da família, garantindo que não comece na sala de estar (livingRoom)
	var room_keys = rooms.keys()
	var new_family_location_key: String
	do:
		new_family_location_key = room_keys[randi() % room_keys.size()]
	while new_family_location_key == "livingRoom" # Assumindo "livingRoom" como a sala inicial do jogador
	family_location = new_family_location_key

	# Emite todos os sinais para garantir que a UI seja completamente atualizada.
	money_changed.emit(money)
	caught_changed.emit(caught_count)
	game_message_changed.emit(game_message)
	game_over_status_changed.emit(is_game_over)
	qte_active_changed.emit(is_qte_active)
	family_location_changed.emit(family_location)
	game_reset.emit() # Sinal genérico para reset do jogo
