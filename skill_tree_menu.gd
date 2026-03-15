extends Control

# Chamado quando o botão "Comprar salamander" for clicado na UI
func _on_buy_salamander_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_salamander:
		game.magic_scrolls -= cost
		game.unlocked_salamander = true
		
		print("salamander Adquirida! +25% Velocidade e Valor para o Fogo!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		
		# Aqui você pode mudar a cor do botão na Skill Tree para mostrar que foi comprado
		# Exemplo: $Botaosalamander.modulate = Color.GREEN
		# $Botaosalamander.disabled = true
	else:
		if game.unlocked_salamander:
			print("Você já possui a salamander!")
		else:
			print("Pergaminhos Mágicos insuficientes!")

# Chamado quando o botão "Comprar armadillo" for clicado na UI
func _on_buy_armadillo_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_armadillo:
		game.magic_scrolls -= cost
		game.unlocked_unlocked_armadillo = true
		
		print("unlocked_armadillo Adquirida! +25% Velocidade e Valor para o Fogo!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		
		# Aqui você pode mudar a cor do botão na Skill Tree para mostrar que foi comprado
		# Exemplo: $Botaosalamander.modulate = Color.GREEN
		# $Botaosalamander.disabled = true
	else:
		if game.unlocked_salamander:
			print("Você já possui a salamander!")
		else:
			print("Pergaminhos Mágicos insuficientes!")

# Chamado quando o botão "Comprar salamander" for clicado na UI
func _on_buy_ray_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_ray:
		game.magic_scrolls -= cost
		game.unlocked_ray = true
		
		print("ray Adquirida! +25% Velocidade e Valor para o Fogo!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		
		# Aqui você pode mudar a cor do botão na Skill Tree para mostrar que foi comprado
		# Exemplo: $Botaosalamander.modulate = Color.GREEN
		# $Botaosalamander.disabled = true
	else:
		if game.unlocked_ray:
			print("Você já possui a salamander!")
		else:
			print("Pergaminhos Mágicos insuficientes!")

# Chamado quando o botão "Comprar parakeet" for clicado na UI
func _on_buy_parakeet_pressed() -> void:
	var game = get_node("/root/Game")
	var cost = 1 # Conforme a tabela do GDD, custa 1 Pergaminho
	
	# Checa se o jogador tem o pergaminho e se já não comprou antes
	if game.magic_scrolls >= cost and not game.unlocked_parakeet:
		game.magic_scrolls -= cost
		game.unlocked_parakeet = true
		
		print("parakeet Adquirida! +25% Velocidade e Valor para o Fogo!")
		
		# Atualiza os números na tela principal do jogo
		game.update_ui() 
		
		# Aqui você pode mudar a cor do botão na Skill Tree para mostrar que foi comprado
		# Exemplo: $Botaosalamander.modulate = Color.GREEN
		# $Botaosalamander.disabled = true
	else:
		if game.unlocked_parakeet:
			print("Você já possui a parakeet!")
		else:
			print("Pergaminhos Mágicos insuficientes!")
