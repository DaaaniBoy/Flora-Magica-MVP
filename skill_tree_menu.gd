extends Control

@onready var magic_scrolls = $MagicScrolls


func _ready():
	update_tree_visuals()
# --- RECUPERANDO O BOTÃO DE VOLTAR ---
func _on_back_to_garden_pressed() -> void:
	hide() # Esconde o menu e revela o jardim

# --- ATUALIZA O VISUAL DA ÁRVORE ---
func update_tree_visuals():
	var game = get_node("/root/Game")
	
		# Atualiza o texto dos Pergaminhos na tela da Skill Tree!
	if $MagicScrolls: 
		$MagicScrolls.text = "Magic Scrolls: " + str(game.magic_scrolls)
	# --- COLUNA DO FOGO ---
	if game.unlocked_salamander:
		$ZoologyPowerUp/BuyFireAnimal.disabled = true
		$ZoologyPowerUp/BuyFireAnimal.text = "Animal Companion (Fire)\n[BOUGHT]"
		if game.fire_collecting_level < 5:
			$ZoologyPowerUp2/BuyFireCollecting.disabled = false
			var next_cost = game.fire_collecting_level + 1 
			$ZoologyPowerUp2/BuyFireCollecting.text = "Fire Collecting\nCost: " + str(next_cost) + " Scroll\n(" + str(game.fire_collecting_level) + "/5 LVL)"
		else:
			$ZoologyPowerUp2/BuyFireCollecting.disabled = true
			$ZoologyPowerUp2/BuyFireCollecting.text = "Fire Collecting\n[MAX LEVEL]"
	else:
		$ZoologyPowerUp2/BuyFireCollecting.disabled = true
		
	# --- COLUNA DA TERRA ---
	if game.unlocked_armadillo:
		$ZoologyPowerUp/BuyEarthAnimal.disabled = true
		$ZoologyPowerUp/BuyEarthAnimal.text = "Animal Companion (Earth)\n[BOUGHT]"
		if game.earth_collecting_level < 5: # CORRIGIDO: Agora checa a Terra!
			$ZoologyPowerUp2/BuyEarthCollecting.disabled = false
			var next_cost = game.earth_collecting_level + 1 
			$ZoologyPowerUp2/BuyEarthCollecting.text = "Earth Collecting\nCost: " + str(next_cost) + " Scroll\n(" + str(game.earth_collecting_level) + "/5 LVL)"
		else:
			$ZoologyPowerUp2/BuyEarthCollecting.disabled = true
			$ZoologyPowerUp2/BuyEarthCollecting.text = "Earth Collecting\n[MAX LEVEL]"
	else:
		$ZoologyPowerUp2/BuyEarthCollecting.disabled = true
		
	# --- COLUNA DA ÁGUA ---
	if game.unlocked_ray:
		$ZoologyPowerUp/BuyWaterAnimal.disabled = true
		$ZoologyPowerUp/BuyWaterAnimal.text = "Animal Companion (Water)\n[BOUGHT]"
		if game.water_collecting_level < 5: # CORRIGIDO: Agora checa a Água!
			$ZoologyPowerUp2/BuyWaterCollecting.disabled = false
			var next_cost = game.water_collecting_level + 1 
			$ZoologyPowerUp2/BuyWaterCollecting.text = "Water Collecting\nCost: " + str(next_cost) + " Scroll\n(" + str(game.water_collecting_level) + "/5 LVL)"
		else:
			$ZoologyPowerUp2/BuyWaterCollecting.disabled = true
			$ZoologyPowerUp2/BuyWaterCollecting.text = "Water Collecting\n[MAX LEVEL]"
	else:
		$ZoologyPowerUp2/BuyWaterCollecting.disabled = true
		
	# --- COLUNA DO AR ---
	if game.unlocked_parakeet:
		$ZoologyPowerUp/BuyAirAnimal.disabled = true
		$ZoologyPowerUp/BuyAirAnimal.text = "Animal Companion (Air)\n[BOUGHT]"
		if game.air_collecting_level < 5: # CORRIGIDO: Agora checa o Ar!
			$ZoologyPowerUp2/BuyAirCollecting.disabled = false
			var next_cost = game.air_collecting_level + 1 
			$ZoologyPowerUp2/BuyAirCollecting.text = "Air Collecting\nCost: " + str(next_cost) + " Scroll\n(" + str(game.air_collecting_level) + "/5 LVL)"
		else:
			$ZoologyPowerUp2/BuyAirCollecting.disabled = true
			$ZoologyPowerUp2/BuyAirCollecting.text = "Air Collecting\n[MAX LEVEL]"
	else:
		$ZoologyPowerUp2/BuyAirCollecting.disabled = true


# Chamado quando o botão "Comprar salamander" for clicado na UI
func _on_buy_salamander_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_salamander:
		game.magic_scrolls -= cost
		game.unlocked_salamander = true
		
		print("Salamander Adopted! +25% Growing Speed and Sell Value to the Fire!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		update_tree_visuals() # Faltava isso nos outros!
	elif game.unlocked_salamander:
		print("Você já possui a Salamander!")
	else:
		print("Pergaminhos insuficientes!")

# Chamado quando o botão "Comprar armadillo" for clicado na UI
func _on_buy_armadillo_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_armadillo:
		game.magic_scrolls -= cost
		game.unlocked_armadillo = true
		
		print("Armadillo Adopeted! +25% Growing Speed and Sell Value to the Earth!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		update_tree_visuals() # Faltava isso!
	elif game.unlocked_armadillo:
		print("Você já possui o Armadillo!")
	else:
		print("Pergaminhos insuficientes!")

# Chamado quando o botão "Comprar salamander" for clicado na UI
func _on_buy_ray_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_ray:
		game.magic_scrolls -= cost
		game.unlocked_ray = true
		
		print("Ray Adopted! +25% Growing Speed and Sell Value to the Water!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		update_tree_visuals() # Faltava isso!
	elif game.unlocked_ray:
		print("Você já possui a Ray!")
	else:
		print("Pergaminhos insuficientes!")

# Chamado quando o botão "Comprar parakeet" for clicado na UI
func _on_buy_parakeet_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_parakeet:
		game.magic_scrolls -= cost
		game.unlocked_parakeet = true
		
		print("Parakeet Adopted! +25% Growing Speed and Sell Vallue to the Air!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		update_tree_visuals()
		# Aqui você pode mudar a cor do botão na Skill Tree para mostrar que foi comprado
	elif game.unlocked_parakeet:
		print("Você já possui o Parakeet!")
	else:
		print("Pergaminhos insuficientes!")

# --- BOTÕES DE COMPRA DE COLETA ---

func _on_buy_fire_collecting_pressed() -> void:
	var game = get_node("/root/Game")
	if game.unlocked_salamander and game.fire_collecting_level < 5:
		var cost = game.fire_collecting_level + 1 
		if game.magic_scrolls >= cost:
			game.magic_scrolls -= cost
			game.fire_collecting_level += 1 # CORRETO: Upa Fogo
			update_tree_visuals()
			game.update_ui()

func _on_buy_earth_collecting_pressed() -> void:
	var game = get_node("/root/Game")
	if game.unlocked_armadillo and game.earth_collecting_level < 5:
		var cost = game.earth_collecting_level + 1 
		if game.magic_scrolls >= cost:
			game.magic_scrolls -= cost
			game.earth_collecting_level += 1 # CORRIGIDO: Upa Terra!
			update_tree_visuals()
			game.update_ui()

func _on_buy_water_collecting_pressed() -> void:
	var game = get_node("/root/Game")
	if game.unlocked_ray and game.water_collecting_level < 5:
		var cost = game.water_collecting_level + 1 
		if game.magic_scrolls >= cost:
			game.magic_scrolls -= cost
			game.water_collecting_level += 1 # CORRIGIDO: Upa Água!
			update_tree_visuals()
			game.update_ui()

func _on_buy_air_collecting_pressed() -> void:
	var game = get_node("/root/Game")
	if game.unlocked_parakeet and game.air_collecting_level < 5:
		var cost = game.air_collecting_level + 1 
		if game.magic_scrolls >= cost:
			game.magic_scrolls -= cost
			game.air_collecting_level += 1 # CORRIGIDO: Upa Ar!
			update_tree_visuals()
			game.update_ui()
