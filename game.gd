extends Node2D

# Precisamos do Enum aqui também para o jogo saber o que estamos escolhendo
enum Element {Water, Fire, Earth, Air}
var chosen_element = Element.Water # Padrão para os novos vasos

# Variáveis do GDD
var player_gold: int = 0
var essence_value = 15 

var growing_speed = 1.0 
var growing_speed_level = 0
var growing_speed_max_level = 29
var growing_speed_increase_base_cost = 100

var irrigation_bonus = 2.0 
var irrigation_bonus_level = 0
var irrigation_bonus_max_level = 29
var irrigation_increase_base_cost = 70

var vase_scene = preload("res://Vase.tscn") 
var vase_level = 0
var vase_max_level = 14
var planting_vase

@onready var gold = $Gold
@onready var grid = $GridContainer

func _ready():
	# 1. Cria os 15 slots via código
	for i in range(15):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(125, 125)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.3, 0.3)
		slot.add_theme_stylebox_override("normal", style)
		
		grid.add_child(slot)
		slot.pressed.connect(_on_empty_slot_pressed.bind(slot))

	# 2. Pede para a Godot preparar o vaso inicial apenas quando a tela estiver 100% pronta
	call_deferred("_setup_first_vase")
	$BuyVaseButton.modulate = Color("4a86e8")

# Nova função dedicada a colocar o primeiro vaso no jogo
func _setup_first_vase():
	var first_slot = grid.get_child(7)
	var first_vase = vase_scene.instantiate()
	first_slot.add_child(first_vase)
	
	first_vase.set_anchors_preset(Control.PRESET_FULL_RECT)
	first_vase.offset_left = 0
	first_vase.offset_top = 0
	first_vase.offset_right = 0
	first_vase.offset_bottom = 0
	
	first_slot.disabled = true 
	first_vase.configure_plant(chosen_element)
	
	highlight_empty_slots(false) 
	update_ui()


# --- FUNÇÕES AUXILIARES (DRY) ---

func calculating_upgrade_cost(base: float, multiplier: float, level: int) -> int:
	return roundi(base * pow(multiplier, level))

func update_ui():
	gold.text = "Gold: " + str(player_gold)
	
	var speed_cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
	$GrowingSpeedIncrease.text = "Increase Growing Speed (Cost: " + str(speed_cost) + " Gold)"
	
	var irr_cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
	$IrrigationIncrease.text = "Increase Irrigation Bonus (Cost: " + str(irr_cost) + " Gold)"
	
	# O segredo visual está aqui:
	if planting_vase:
		$BuyVaseButton.text = "Click on an empty slot!"
	else:
		var next_vase_cost = calculating_upgrade_cost(200, 2.0, vase_level)
		$BuyVaseButton.text = "New Vase (Cost: " + str(next_vase_cost) + " Gold)"

# --- LÓGICA DE JOGO ---

func gain_gold():
	player_gold += int(essence_value)
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
			irrigation_bonus += 2.0
			update_ui()
		else:
			print("Insufficient Gold!")

func _on_buy_vase_button_pressed() -> void:
	if vase_level < vase_max_level:
		var cost = calculating_upgrade_cost(200, 2.0, vase_level)
		
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
			
			new_vase.configure_plant(chosen_element)
			
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
				# Slot ocupado = Branco (para não alterar a cor da planta que está por cima)
				slot.modulate = Color.WHITE






func _process(_delta):
	if Input.is_action_just_pressed("tecla_m"):
		add_gold(50000)

func add_gold(quantidade):
	player_gold += quantidade
	update_ui()


# --- SELEÇÃO DE ELEMENTOS ---

func _on_water_button_pressed() -> void:
	chosen_element = Element.Water
	$BuyVaseButton.modulate = Color("4a86e8")
	# Cancela o modo de plantio se você trocar de ideia no meio do caminho
	cancel_planting() 

func _on_fire_button_pressed() -> void:
	chosen_element = Element.Fire
	$BuyVaseButton.modulate = Color("#e06666")
	cancel_planting()

func _on_earth_button_pressed() -> void:
	chosen_element = Element.Earth
	$BuyVaseButton.modulate = Color("#6aa84f")
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
