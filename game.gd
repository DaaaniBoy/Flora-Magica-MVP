extends Node2D

# Precisamos do Enum aqui também para o jogo saber o que estamos escolhendo
enum Element {Fire, Earth, Water, Air, Lava, Vapor, Plasma, Mud, Sand, Ice}
enum Season {Summer, Autumn, Winter, Spring} # NOVO
var chosen_element = Element.Fire # Padrão para os novos vasos
var current_season = Season.Summer # NOVO

# Variáveis do GDD
var player_gold: int = 0
var displayed_gold: int = 0 
var gold_tween: Tween 
var total_accumulated_gold: int = 0 

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

var quality_chance_min = 0 
var quality_chance_max = 100 

var luck_chance_min = 0 
var luck_chance_max = 0 

var vase_scene = preload("res://Vase.tscn") 
var vase_level = 0
var vase_max_level = 24

var positioning_new_vase: bool = false 
var planting_seed: bool = false 
var is_first_free_vase: bool = false 
var seed_buy_count: int = 0 # NOVO: Controla a inflação do preço das sementes
var using_shovel: bool = false # NOVO: Controla se a pá está ativa

# Variáveis de Prestígio (GDD)
var magic_scrolls: int = 0
var prestige_count: int = 0
var global_gold_multiplier: float = 1.0 

# Habilidades de Prestígio - Ramo da Zoologia (Nível 1)
var unlocked_salamander: bool = false # Fire
var unlocked_armadillo: bool = false       # Earh
var unlocked_ray: bool = false       # Water
var unlocked_parakeet: bool = false  # Air

# Habilidades de Prestígio - Ramo da Zoologia (Nível 2 - Coleta Automática)
var fire_collecting_level: int = 0
var earth_collecting_level: int = 0
var water_collecting_level: int = 0
var air_collecting_level: int = 0

# Variaveis para tabela de rendimento
var gold_yield = {
	Element.Fire: 0, Element.Earth: 0, Element.Water: 0, Element.Air: 0,
	Element.Lava: 0, Element.Vapor: 0, Element.Plasma: 0, Element.Mud: 0, Element.Sand: 0, Element.Ice: 0
}

var hovered_flower = null # Rastreia quem o mouse está olhando

@onready var gold = $Gold
@onready var season_label = $SeasonLabel
@onready var grid = $GridContainer
@onready var total_gold_label = $TotalGoldAccumulated
@onready var magic_scrolls_label = $MagicScrolls
@onready var prestige_button = $PrestigeButton
@onready var skill_tree_button = $SkillTreeButton
@onready var skill_tree_menu = $CanvasLayer/SkillTreeMenu 
@onready var plant_seed_button = $PlantSeedButton 
@onready var shovel_button = $ShovelButton # NOVO: Puxa o botão da Pá
@onready var hover_panel = $CanvasLayer/HoverPanel
@onready var hover_label = $CanvasLayer/HoverPanel/MarginContainer/RichTextLabel
@onready var yield_container = $CanvasLayer/YieldPanel/MarginContainer/YieldContainer
@onready var encyclopedia_button = $EncyclopediaButton
@onready var encyclopedia_menu = $CanvasLayer/EncyclopediaMenu

func build_grid():
	for slot in grid.get_children():
		grid.remove_child(slot)
		slot.queue_free()

	var grid_size = 3 
	var slot_size = 125 
	
	if prestige_count == 1:
		grid_size = 4 
		slot_size = 100 
	elif prestige_count >= 2:
		grid_size = 5 
		slot_size = 80 
		
	grid.columns = grid_size
	
	vase_max_level = (grid_size * grid_size) - 1 

	for i in range(grid_size * grid_size):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color.WHITE 
		
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.85, 0.85, 0.85) 
		
		slot.add_theme_stylebox_override("normal", style)
		slot.add_theme_stylebox_override("hover", hover_style) 
		slot.add_theme_stylebox_override("pressed", hover_style) 
		slot.add_theme_stylebox_override("disabled", style) 
		
		slot.set_meta("has_vase", false)
		grid.add_child(slot)
		slot.pressed.connect(_on_empty_slot_pressed.bind(slot))

func _ready():
	build_grid() 
	$BuyVaseButton.modulate = Color("#ffffff")

	# --- CORREÇÃO DE SINAIS DA UI ---
	# Força a conexão do clique via código para evitar bugs se mudar o tipo do botão
	if encyclopedia_button and not encyclopedia_button.pressed.is_connected(_on_encyclopedia_button_pressed):
		encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)
	if skill_tree_button and not skill_tree_button.pressed.is_connected(_on_skill_tree_button_pressed):
		skill_tree_button.pressed.connect(_on_skill_tree_button_pressed)

	# --- LÓGICA DO INÍCIO GRATUITO ---
	is_first_free_vase = true
	positioning_new_vase = true 
	planting_seed = false
	highlight_empty_slots() 
	update_ui()

# --- FUNÇÕES AUXILIARES (DRY) ---

func calculating_upgrade_cost(base: float, multiplier: float, level: int) -> int:
	return roundi(base * pow(multiplier, level))

func update_ui():
	if season_label:
		match current_season:
			Season.Summer:
				season_label.text = "Season: Summer (Fire is abundant, Water is rare)"
				season_label.modulate = Color("#ff0000") 
			Season.Autumn:
				season_label.text = "Season: Autumn (Earth is abundant, Air is rare)"
				season_label.modulate = Color("#6aa84f") 
			Season.Winter:
				season_label.text = "Season: Winter (Water is abundant, Fire is rare)"
				season_label.modulate = Color("#4a86e8") 
			Season.Spring:
				season_label.text = "Season: Spring (Air is abundant, Earth is rare)"
				season_label.modulate = Color("#ff9900") 
	
	if gold_tween and gold_tween.is_running():
		gold_tween.kill()
		
	gold_tween = create_tween()
	gold_tween.tween_method(
		func(valor_atual): 
			displayed_gold = valor_atual 
			gold.text = "Gold: " + str(valor_atual), 
		displayed_gold, 
		player_gold,    
		0.5             
	)
	
	if total_gold_label:
		total_gold_label.text = "Total Accumulated Gold: " + str(total_accumulated_gold)
		
	if magic_scrolls_label:
		magic_scrolls_label.text = "Magic Scrolls: " + str(magic_scrolls)
	
	var speed_cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
	$GrowingSpeedIncrease.text = "Increase Growing Speed (Cost: " + str(speed_cost) + " Gold)"
	
	var irr_cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
	$IrrigationIncrease.text = "Increase Irrigation Bonus (Cost: " + str(irr_cost) + " Gold)"
	
	var sell_cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
	$SellValueIncrese.text = "Increase the Essence Sell Value (Cost: " + str(sell_cost) + " Gold)"
	
	if positioning_new_vase:
		$BuyVaseButton.text = "Click on a locked space!"
	else:
		var next_vase_cost = calculating_upgrade_cost(1000, 1.75, vase_level)
		$BuyVaseButton.text = "New Vase (Cost: " + str(next_vase_cost) + " Gold)"

	# --- NOVO: TEXTO ESCALONADO DA SEMENTE ---
	if plant_seed_button:
		if planting_seed:
			plant_seed_button.text = "Click on an empty vase!"
		else:
			var next_seed_cost = calculating_upgrade_cost(100, 1.10, seed_buy_count)
			plant_seed_button.text = "Plant Seed (Cost: " + str(next_seed_cost) + " Gold)"

	if prestige_button:
		var target = get_prestige_target()
		if total_accumulated_gold >= target:
			prestige_button.disabled = false 
			prestige_button.modulate = Color.SKY_BLUE 
			prestige_button.text = "PRESTIGE READY!"
		else:
			prestige_button.disabled = true 
			prestige_button.modulate = Color.WHITE
			prestige_button.text = "Prestige (" + str(total_accumulated_gold) + " / " + str(target) + ")"

# Botão da Pá
	if shovel_button:
		if using_shovel:
			shovel_button.text = "Click on a Flower to destroy it!"
			shovel_button.modulate = Color("#8fce00") # Vermelho
		else:
			shovel_button.text = "Shovel (Remove Flower)"
			shovel_button.modulate = Color.WHITE

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

func _on_irrigation_increase_pressed() -> void:
	if irrigation_bonus_level < irrigation_bonus_max_level:
		var cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
		if player_gold >= cost:
			player_gold -= cost
			irrigation_bonus_level += 1 
			irrigation_bonus += 0.5
			update_ui()

func _on_sell_value_increse_pressed() -> void:
	if sell_value_level < sell_value_max_level:
		var cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
		if player_gold >= cost:
			player_gold -= cost
			sell_value_level += 1 
			sell_value += 15 
			update_ui()

func _on_buy_vase_button_pressed() -> void:
	if vase_level < vase_max_level:
		var cost = calculating_upgrade_cost(1000, 2.0, vase_level)
		if player_gold >= cost and not positioning_new_vase and not planting_seed:
			player_gold -= cost
			vase_level += 1
			positioning_new_vase = true
			highlight_empty_slots()
			update_ui()

# --- NOVO: COMPRA DE SEMENTE INFLACIONADA ---
func _on_plant_seed_button_pressed() -> void:
	var cost = calculating_upgrade_cost(100, 1.5, seed_buy_count)
	
	if player_gold >= cost and not positioning_new_vase and not planting_seed:
		player_gold -= cost
		planting_seed = true
		seed_buy_count += 1 # Sobe o preço da próxima!
		highlight_empty_slots()
		update_ui()

# --- BOTÃO DA PÁ (REMOVER flower) ---
func _on_shovel_button_pressed() -> void:
	if is_first_free_vase: return # Não deixa usar a pá no tutorial
	
	# Desativa as outras ferramentas se a pá for selecionada
	if not using_shovel:
		if positioning_new_vase or planting_seed:
			cancel_actions()
		using_shovel = true
	else:
		using_shovel = false # Desliga se clicar de novo
		
	highlight_empty_slots()
	update_ui()

func _on_empty_slot_pressed(clicked_slot):
	if positioning_new_vase:
		if clicked_slot.get_meta("has_vase") == false:
			clicked_slot.set_meta("has_vase", true) 
			positioning_new_vase = false
			
			if is_first_free_vase:
				planting_seed = true
				
			highlight_empty_slots()
			update_ui()
			
	elif planting_seed:
		if clicked_slot.get_meta("has_vase") == true and clicked_slot.get_child_count() == 0:
			var new_flower = vase_scene.instantiate()
			clicked_slot.add_child(new_flower)
			
			new_flower.clip_text = true 
			new_flower.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
			new_flower.custom_minimum_size = Vector2.ZERO 
			new_flower.size = clicked_slot.size 
			
			new_flower.set_anchors_preset(Control.PRESET_FULL_RECT)
			new_flower.offset_left = 0
			new_flower.offset_top = 0
			new_flower.offset_right = 0
			new_flower.offset_bottom = 0
			
			new_flower.configure_flower(chosen_element)
			
			planting_seed = false
			if is_first_free_vase:
				is_first_free_vase = false 
				
			highlight_empty_slots()
			update_ui()
			update_all_flowers_visuals()
				
	elif using_shovel:
		print("Você precisa clicar em cima de uma flower para removê-la!")
			
		highlight_empty_slots()
		update_ui()

func highlight_empty_slots():
	for slot in grid.get_children():
		if slot is BaseButton:
			var has_vase = slot.get_meta("has_vase")
			var has_flower = slot.get_child_count() > 0
			
			if has_flower:
				slot.self_modulate = Color.WHITE
				slot.disabled = true
			elif has_vase:
				if planting_seed:
					slot.self_modulate = Color("#008000") 
					slot.disabled = false
				else:
					slot.self_modulate = Color("#421010") 
					slot.disabled = true
			else:
				if positioning_new_vase:
					slot.self_modulate = Color("#6fa8dc") 
					slot.disabled = false
				else:
					slot.self_modulate = Color("#333333") 
					slot.disabled = true

func show_flower_tooltip(flower: Button):
	hovered_flower = flower
	hover_panel.show()
	update_tooltip_text()

func hide_flower_tooltip():
	hovered_flower = null
	hover_panel.hide()

func update_tooltip_text():
	if not hovered_flower: return
	
	# Pega os modificadores atuais daquela flower específica
	var mods = hovered_flower.get_current_modifiers()
	
	# Calcula o TEMPO de crescimento (em segundos)
	var base_time = hovered_flower.base_growing_speed
	var final_speed_mult = growing_speed * mods["speed_mod"]
	var final_time = base_time / final_speed_mult if final_speed_mult > 0 else base_time
	
	# Calcula os outros status
	var base_val = hovered_flower.base_sell_value + sell_value
	# No game.gd, dentro de update_tooltip_text():
	var final_val = (hovered_flower.base_sell_value + sell_value) * mods["value_mod"]
	var final_quality = hovered_flower.base_quality_chance * (1.0 + mods["quality_mod"])
	var final_luck = hovered_flower.base_luck_chance * (1.0 + mods["luck_mod"])
	
	# Função interna para pintar o texto de verde ou vermelho automaticamente
	var format_stat = func(base, final, sufix, is_inverted=false):
		if final > base + 0.01: # Se o status final for maior que a base
			var color = "#008000" if not is_inverted else "#ff0000" # Verde (ou vermelho se for tempo)
			return str(round(base)) + sufix + " -> [color=" + color + "]" + str(round(final)) + sufix + "[/color]"
		elif final < base - 0.01: # Se for menor
			var color = "#ff0000" if not is_inverted else "#008000" # Vermelho (ou verde se for tempo)
			return str(round(base)) + sufix + " -> [color=" + color + "]" + str(round(final)) + sufix + "[/color]"
		else: # Se não houver buff/debuff
			return str(round(base)) + sufix
			
	var text = "[center][b]Flower Status[/b][/center]\n\n"
	
	# Nota: Em "Tempo", menos segundos é algo BOM, então ativamos a inversão (is_inverted=true)
	# Use ceil() no lugar do base_time e final_time na hora de chamar a função format_stat
	text += "Growing Time: " + format_stat.call(ceil(base_time), ceil(final_time), "s", true) + "\n"
	text += "Sell Value: " + format_stat.call(base_val, final_val, " Gold") + "\n"
	text += "Harvest Quality: " + format_stat.call(hovered_flower.base_quality_chance, final_quality, "%") + "\n"
	text += "Cultivator's Luck: " + format_stat.call(hovered_flower.base_luck_chance, final_luck, "%")
	
	hover_label.text = text

func cancel_actions():
	if is_first_free_vase:
		return 
		
	if positioning_new_vase:
		positioning_new_vase = false
		var cost = calculating_upgrade_cost(1000, 2.0, vase_level - 1)
		player_gold += cost
		vase_level -= 1
		highlight_empty_slots()
		update_ui()
	elif planting_seed:
		planting_seed = false
		# Devolve o Gold com o preço correto
		var cost = calculating_upgrade_cost(100, 1.10, seed_buy_count - 1)
		player_gold += cost 
		seed_buy_count -= 1 # Volta o custo pra trás
		highlight_empty_slots()
		update_ui()
		
	elif using_shovel: # NOVO
		using_shovel = false
		highlight_empty_slots()
		update_ui()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		cancel_actions()
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_actions()

func get_prestige_target() -> int:
	if prestige_count == 0:
		return 100000   # Primeiro prestígio
	elif prestige_count == 1:
		return 1000000  # Segundo prestígio
	else:
		# Do terceiro em diante, cresce exponencialmente baseado em 1 milhão
		return roundi(1000000 * pow(1.5, prestige_count - 1))

func do_prestige():
	if total_accumulated_gold >= get_prestige_target():
		var scrolls_earned = floor (sqrt (int(total_accumulated_gold / get_prestige_target())))*5
		magic_scrolls += scrolls_earned
		
		prestige_count += 1
		global_gold_multiplier = 1.0 + (prestige_count * 0.05) 
		
		current_season = ((current_season + 1) % 4) as Season
		
		player_gold = 0
		total_accumulated_gold = 0 
		
		growing_speed_level = 0
		growing_speed = 1.0
		
		irrigation_bonus_level = 0
		irrigation_bonus = 1.0
		
		sell_value_level = 0
		sell_value = 0 
		
		vase_level = 0
		seed_buy_count = 0 # NOVO: Zera a inflação das sementes no Prestígio!
		
		for element in gold_yield.keys():
			gold_yield[element] = 0
		update_yield_ui()
		
		build_grid()
		
		is_first_free_vase = true
		positioning_new_vase = true 
		planting_seed = false
		highlight_empty_slots() 
		update_ui()


func add_gold(quantity):
	player_gold += quantity
	total_accumulated_gold += quantity 
	update_ui()

func _on_prestige_button_pressed() -> void:
	do_prestige()

func _on_skill_tree_button_pressed() -> void:
	if skill_tree_menu:
		skill_tree_menu.update_tree_visuals() 
		skill_tree_menu.show()
		
func _on_encyclopedia_button_pressed() -> void:
	if encyclopedia_menu:
		encyclopedia_menu.open_encyclopedia()

func _on_fire_button_pressed() -> void:
	chosen_element = Element.Fire
	if plant_seed_button: plant_seed_button.modulate = Color("#ff0000")

func _on_earth_button_pressed() -> void:
	chosen_element = Element.Earth
	if plant_seed_button: plant_seed_button.modulate = Color("#6aa84f")

func _on_water_button_pressed() -> void:
	chosen_element = Element.Water
	if plant_seed_button: plant_seed_button.modulate = Color("4a86e8")

func _on_air_button_pressed() -> void:
	chosen_element = Element.Air
	if plant_seed_button: plant_seed_button.modulate = Color("#ff9900")
	
func record_gold_yield(element: Element, amount: int):
	gold_yield[element] += amount
	update_yield_ui()

func update_yield_ui():
	if not yield_container: return
	
	# Limpa os dados antigos para desenhar os novos
	for child in yield_container.get_children():
		child.queue_free()
		
	# Encontra qual elemento rendeu mais ouro para basear o tamanho máximo da barra
	var max_gold = 0
	for element in gold_yield:
		if gold_yield[element] > max_gold:
			max_gold = gold_yield[element]
			
	if max_gold == 0: return # Se não colheu nada ainda, não desenha nada
	
	# Título do Gráfico
	var title = Label.new()
	title.text = "Yielding Chart"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yield_container.add_child(title)
	
	# --- A MÁGICA DA ORDENAÇÃO ACONTECE AQUI ---
	var sorted_elements = gold_yield.keys()
	# Ordena a lista comparando o ouro do elemento A com o do elemento B (Maior pro menor)
	sorted_elements.sort_custom(func(a, b): return gold_yield[a] > gold_yield[b])
	
	# Cria uma barra para cada elemento que já rendeu algum ouro (agora usando a lista ordenada!)
	for element in sorted_elements:
		var amount = gold_yield[element]
		if amount > 0:
			var hbox = HBoxContainer.new()
			
			var label = Label.new()
			label.text = str(Element.keys()[element]) + ": " + str(amount)
			label.custom_minimum_size = Vector2(80, 0) # Deixa os nomes alinhados
			
			var progress = ProgressBar.new()
			progress.max_value = max_gold
			progress.value = amount
			progress.custom_minimum_size = Vector2(150, 20) # Tamanho da barra
			progress.show_percentage = false
			
			# Pintar a barra com a cor do elemento
			var style = StyleBoxFlat.new()
			match element:
				Element.Fire: style.bg_color = Color("#ff0000")
				Element.Earth: style.bg_color = Color("#6aa84f")
				Element.Water: style.bg_color = Color("#4a86e8")
				Element.Air: style.bg_color = Color("#ff9900")
			progress.add_theme_stylebox_override("fill", style)
			
			hbox.add_child(label)
			hbox.add_child(progress)
			yield_container.add_child(hbox)

func update_all_flowers_visuals():
	for slot in grid.get_children():
		if slot.get_child_count() > 0:
			var flower = slot.get_child(0)
			if flower.has_method("update_buff_visuals"):
				flower.update_buff_visuals()



func _process(_delta):
	if Input.is_action_just_pressed("tecla_m"):
		add_gold(50000)
	if Input.is_action_just_pressed("tecla_p"):
		do_prestige()
		
	if hover_panel and hover_panel.visible:
		var mouse_pos = get_global_mouse_position()
		var panel_size = hover_panel.size
		var screen_size = get_viewport_rect().size
		
		# Posição inicial desejada (um pouco para a direita e para baixo)
		var target_pos = mouse_pos + Vector2(15, 15)
		
		# Impede de vazar pela Direita da tela
		if target_pos.x + panel_size.x > screen_size.x:
			target_pos.x = screen_size.x - panel_size.x - 10 # Dá 10px de folga
			
		# Impede de vazar pela parte de Baixo da tela
		if target_pos.y + panel_size.y > screen_size.y:
			# Joga o painel para CIMA do mouse, para não ficar embaixo do dedo/cursor
			target_pos.y = mouse_pos.y - panel_size.y - 15 
			
		hover_panel.global_position = target_pos
		update_tooltip_text() # ATUALIZA EM TEMPO REAL
