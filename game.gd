extends Node2D

# Precisamos do Enum aqui também para o jogo saber o que estamos escolhendo
enum Element {Fire, Earth, Water, Air}
var chosen_element = Element.Fire # Padrão para os novos vasos

# Variáveis do GDD
var player_gold: int = 0
var displayed_gold: int = 0 # Guarda o valor visual que está na tela agora
var gold_tween: Tween # Guarda a animação para não bugar se você clicar muito rápido
var total_accumulated_gold: int = 0 # NOVO: Guarda o ouro total de toda a partida

var growing_speed = 1.0 
var growing_speed_level = 0
var growing_speed_max_level = 29
var growing_speed_increase_base_cost = 500

var irrigation_bonus = 2.0 
var irrigation_bonus_level = 0
var irrigation_bonus_max_level = 29
var irrigation_increase_base_cost = 350

var sell_value = 0
var sell_value_level = 0
var sell_value_max_level = 29
var sell_value_base_cost = 750

var quality_chance_min = 0 # Quality of Harvest Attribute
var quality_chance_max = 100 # Quality of Harvest Attribute

var luck_chance_min = 0 # Farmer's Luck Attribute
var luck_chance_max = 0 # Farmer's Luck Attribute

var vase_scene = preload("res://Vase.tscn") 
var vase_level = 0
var vase_max_level = 14
var planting_vase

# Variáveis de Prestígio (GDD)
var magic_scrolls: int = 0
var prestige_count: int = 0
var global_gold_multiplier: float = 1.0 # Começa em 100% de ganho normal

# Habilidades de Prestígio - Ramo da Zoologia (Nível 1)
var unlocked_salamander: bool = false # Fire
var unlocked_armadillo: bool = false       # Earh
var unlocked_ray: bool = false       # Water
var unlocked_parakeet: bool = false  # Air

# Habilidades de Prestígio - Ramo da Zoologia (Nível 2 - Coleta Automática)
var auto_collect_fire: bool = true #TESTE
var auto_collect_earth: bool = false
var auto_collect_water: bool = false
var auto_collect_air: bool = false

@onready var gold = $Gold
@onready var grid = $GridContainer
@onready var total_gold_label = $TotalGoldAccumulated
@onready var magic_scrolls_label = $MagicScrolls

func _ready():
	# 1. Cria os 15 slots via código
	for i in range(9):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(125, 125)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		slot.add_theme_stylebox_override("normal", style)
		
		grid.add_child(slot)
		slot.pressed.connect(_on_empty_slot_pressed.bind(slot))

	# 2. Pede para a Godot preparar o vaso inicial apenas quando a tela estiver 100% pronta
	call_deferred("_setup_first_vase")
	$BuyVaseButton.modulate = Color("e06666")

# Nova função dedicada a colocar o primeiro vaso no jogo
func _setup_first_vase():
	var first_slot = grid.get_child(4)
	var first_vase = vase_scene.instantiate()
	first_slot.add_child(first_vase)
	
	first_vase.set_anchors_preset(Control.PRESET_FULL_RECT)
	first_vase.offset_left = 1
	first_vase.offset_top = 1
	first_vase.offset_right = 1
	first_vase.offset_bottom = 1
	
	first_slot.disabled = true 
	first_vase.configure_flower(chosen_element)
	
	highlight_empty_slots(false) 
	update_ui()


# --- FUNÇÕES AUXILIARES (DRY) ---

func calculating_upgrade_cost(base: float, multiplier: float, level: int) -> int:
	return roundi(base * pow(multiplier, level))

func update_ui():
	# --- ANIMAÇÃO DO OURO ---
	# Se o jogador clicar várias vezes rápido, cancelamos a animação anterior para não dar conflito
	if gold_tween and gold_tween.is_running():
		gold_tween.kill()
		
	# Cria a nova animação
	gold_tween = create_tween()
	gold_tween.tween_method(
		func(valor_atual): 
			displayed_gold = valor_atual # Atualiza a nossa memória visual
			gold.text = "Gold: " + str(valor_atual), # Atualiza o texto na tela
		displayed_gold, # Começa a contar a partir do número que já estava na tela...
		player_gold,    # ...e vai até o valor real que o jogador tem agora
		0.5             # Duração da animação em segundos (0.5 = meio segundo)
	)
	# Atualiza o texto do Ouro Total Acumulado
	if total_gold_label:
		total_gold_label.text = "Total Accumulated Gold: " + str(total_accumulated_gold)
	
	# Atualiza o texto do Ouro Total Acumulado
	if total_gold_label:
		total_gold_label.text = "Total Accumulated Gold: " + str(total_accumulated_gold)
		
	# Atualiza o texto dos Pergaminhos Mágicos
	if magic_scrolls_label:
		magic_scrolls_label.text = "Magic Scrolls: " + str(magic_scrolls)
	
	# --- ATUALIZAÇÃO DOS CUSTOS (Instantânea) ---
	var speed_cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
	$GrowingSpeedIncrease.text = "Increase Growing Speed (Cost: " + str(speed_cost) + " Gold)"
	
	var irr_cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
	$IrrigationIncrease.text = "Increase Irrigation Bonus (Cost: " + str(irr_cost) + " Gold)"
	
	var sell_cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
	$SellValueIncrese.text = "Increase the Essence Sell Value (Cost: " + str(sell_cost) + " Gold)"
	
	if planting_vase:
		$BuyVaseButton.text = "Click on an empty slot!"
	else:
		var next_vase_cost = calculating_upgrade_cost(1000, 2.0, vase_level)
		$BuyVaseButton.text = "New Vase (Cost: " + str(next_vase_cost) + " Gold)"

# --- LÓGICA DE JOGO ---

func gain_gold():
	player_gold += int(sell_value)
	update_ui()

func _on_growing_speed_increase_pressed() -> void:
	if growing_speed_level < growing_speed_max_level:
		var cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
		if player_gold >= cost:
			player_gold -= cost
			growing_speed_level += 1
			growing_speed += 2.0
			update_ui()
		else:
			print("Insufficient Gold!")

func _on_irrigation_increase_pressed() -> void:
	if irrigation_bonus_level < irrigation_bonus_max_level:
		var cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
		if player_gold >= cost:
			player_gold -= cost
			irrigation_bonus_level += 1 
			irrigation_bonus += 1.0
			update_ui()
		else:
			print("Insufficient Gold!")

func _on_sell_value_increse_pressed() -> void:
	if sell_value_level < sell_value_max_level:
		var cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
		if player_gold >= cost:
			player_gold -= cost
			sell_value_level += 1 
			sell_value += 15
			update_ui()
		else:
			print("Insufficient Gold!")

func _on_buy_vase_button_pressed() -> void:
	if vase_level < vase_max_level:
		var cost = calculating_upgrade_cost(1000, 2.0, vase_level)
		
		if player_gold >= cost and not planting_vase:
			player_gold -= cost
			vase_level += 1
			planting_vase = true
			
			# Aqui você pode mudar para uma cor de destaque maior se quiser, 
			# mas como eles já começam verdes, vamos apenas atualizar a UI
			highlight_empty_slots(true) 
			update_ui()
		elif player_gold < cost:
			print("Insufficient Gold!")

func _on_empty_slot_pressed(clicked_slot):
	if planting_vase:
		if clicked_slot.get_child_count() == 0:
			var new_vase = vase_scene.instantiate()
			clicked_slot.add_child(new_vase)
			
			new_vase.set_anchors_preset(Control.PRESET_FULL_RECT)
			new_vase.offset_left = 0
			new_vase.offset_top = 0
			new_vase.offset_right = 0
			new_vase.offset_bottom = 0
			clicked_slot.disabled = true 
			
			new_vase.configure_flower(chosen_element)
			
			planting_vase = false 
			
			# NOVO: Atualiza a pintura. O slot recém-ocupado vai perder a cor verde.
			highlight_empty_slots(true) 
			update_ui()
		else:
			print("Slot já ocupado!")

func highlight_empty_slots(is_planting: bool):
	for slot in grid.get_children():
		if slot is BaseButton:
			if slot.get_child_count() == 0:
				# Slot vazio = Verde (ou cor da sua preferência)
				slot.modulate = Color(0.2, 0.4, 0.2) # Verde escuro para fundo
				if is_planting and planting_vase:
					slot.modulate = Color(0.5, 1.0, 0.5) # Verde claro quando estiver segurando o vaso
			else:
				# Slot ocupado = Branco (para não alterar a cor da flor que está por cima)
				slot.modulate = Color.WHITE

# --- SELEÇÃO DE ELEMENTOS ---

func _on_fire_button_pressed() -> void:
	chosen_element = Element.Fire
	$BuyVaseButton.modulate = Color("#e06666")
	cancel_planting()
func _on_earth_button_pressed() -> void:
	chosen_element = Element.Earth
	$BuyVaseButton.modulate = Color("#6aa84f")
	cancel_planting()
func _on_water_button_pressed() -> void:
	chosen_element = Element.Water
	$BuyVaseButton.modulate = Color("4a86e8")
	# Cancela o modo de plantio se você trocar de ideia no meio do caminho
	cancel_planting() 
func _on_air_button_pressed() -> void:
	chosen_element = Element.Air
	$BuyVaseButton.modulate = Color("#ff9900")
	cancel_planting()

# Função auxiliar para evitar bugs caso você clique no elemento 
# DEPOIS de já ter clicado em "New Vase"
func cancel_planting():
	if planting_vase:
		planting_vase = false
		highlight_empty_slots(false)
		# Devolve o ouro já que a compra foi cancelada
		var cost = calculating_upgrade_cost(200, 2.0, vase_level - 1)
		player_gold += cost
		vase_level -= 1
		update_ui()

func do_prestige():
	# 1. Checa se o jogador atingiu o mínimo de 1 Milhão
	if total_accumulated_gold >= 100000:
		
		# 2. Calcula os Pergaminhos ganhos (Ouro / 1 Milhão)
		var scrolls_earned = int(total_accumulated_gold / 100000)
		magic_scrolls += scrolls_earned
		
		# 3. Aumenta o contador de prestígio e o bônus global (0.5% = 0.005)
		prestige_count += 1
		global_gold_multiplier = 1.0 + (prestige_count * 0.05) 
		
		print("PRESTÍGIO! Você ganhou ", scrolls_earned, " Pergaminhos Mágicos!")
		
		# 4. Reseta a economia e os upgrades
		player_gold = 0
		total_accumulated_gold = 0 # Zeramos para ele ter que farmar 1 milhão de novo na nova run
		
		growing_speed_level = 0
		growing_speed = 1.0
		
		irrigation_bonus_level = 0
		irrigation_bonus = 2.0
		
		sell_value_level = 0
		sell_value = 0 # Zero, como corrigimos antes!
		
		vase_level = 0
		planting_vase = false
		
		# 5. Limpa o Jardim (Remove todas as flores plantadas)
		for slot in grid.get_children():
			for child in slot.get_children():
				child.queue_free() # Destrói a flor
			
			# Devolve o slot ao estado original
			slot.disabled = false 
			
			# FORÇA o botão a voltar para a cor cinza escuro original do slot vazio
			# Isso garante que ele não fique "preso" no Color.WHITE de quando estava ocupado
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.4, 0.2)
			slot.add_theme_stylebox_override("normal", style)
			slot.modulate = Color.WHITE # Reseta o modulate para não misturar com o StyleBox
			
		# 6. Recomeça o ciclo do jogo
		call_deferred("_setup_first_vase")
		update_ui()
		
	else:
		print("Ouro insuficiente! Necessário 1.000.000 para o Prestígio.")




func _process(_delta):
	if Input.is_action_just_pressed("tecla_m"):
		add_gold(50000)
		
	# Atalho para testar o prestígio
	if Input.is_action_just_pressed("tecla_p"):
		do_prestige()

func add_gold(quantity):
	player_gold += quantity
	total_accumulated_gold += quantity 
	update_ui()
