extends Button

# Criando a Classe base
class_name Flor

# Propriedades da classe (atributos)
var flower_cost: int
var flower_progress: float
var base_growing_speed: int # Growing Speed Attribute
var base_sell_value: int # Sell Value Attribute
var base_quality_chance: int # Quality of Harvest Attribute
var base_luck_chance: int # Farmer's Luck Attribute
enum Element {Fire, Earth, Water, Air} #Possible Elements

var current_type = Element.Fire

func configure_flower(element_type):
	current_type = element_type
	
	# Reseta os atributos para o padrão ANTES de aplicar a identidade
	base_growing_speed = 0 
	base_sell_value = 0
	base_quality_chance = 0
	base_luck_chance = 0
	
	match current_type:
		Element.Fire: # EXPENSIVE
			flower_progress = 120
			base_growing_speed = 120 # Growing Speed Attribute
			base_sell_value = 200 # Sell Value Attribute
			base_quality_chance = 25 # Quality of Harvest Attribute
			base_luck_chance = 25    # Farmer's Luck Attribute
			modulate = Color("#e06666")
		Element.Earth: # QUALITY
			flower_progress = 180
			base_growing_speed = 180 # Growing Speed Attribute
			base_sell_value = 100 # Sell Value Attribute
			base_quality_chance = 50 # Quality of Harvest Attribute
			base_luck_chance = 25    # Farmer's Luck Attribute
			modulate = Color("#6aa84f")
		Element.Water: # FAST
			flower_progress = 90
			base_growing_speed = 90 # Growing Speed Attribute
			base_sell_value = 150 # Sell Value Attribute
			base_quality_chance = 25 # Quality of Harvest Attribute
			base_luck_chance = 25    # Farmer's Luck Attribute
			modulate = Color("4a86e8")
		Element.Air: # LUCK
			flower_progress = 120
			base_growing_speed = 120 # Growing Speed Attribute
			base_sell_value = 150 # Sell Value Attribute
			base_quality_chance = 25 # Quality of Harvest Attribute
			base_luck_chance = 50 # Farmer's Luck Attribute
			modulate = Color("#ff9900")
	
	flower_progress = base_growing_speed
	update_visual_vase()

func _ready():
	update_visual_vase()

func _process(delta):
	if flower_progress > 0:
		var current_speed_mod = 1.0
		var adjacents = get_adjacents()
		
		# --- AURA: VELOCIDADE ---
		if current_type == Element.Fire:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod -= 0.25 
		elif current_type == Element.Earth:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod += 0.25 
		elif current_type == Element.Water:
			for adj in adjacents:
				if adj.current_type == Element.Earth: 
					current_speed_mod += 0.25 
				if adj.current_type == Element.Fire:
					current_speed_mod -= 0.25 
		elif current_type == Element.Air:
			pass # Flores de ar não sofrem modificação de velocidade aqui
		
		# --- BÔNUS DOS COMPANHEIROS ANIMAIS (Velocidade) ---
		var game = get_node("/root/Game")
		if current_type == Element.Fire and game.unlocked_salamander:
			current_speed_mod += 0.25
		elif current_type == Element.Earth and game.unlocked_armadillo:
			current_speed_mod += 0.25
		elif current_type == Element.Water and game.unlocked_ray:
			current_speed_mod += 0.25
		elif current_type == Element.Air and game.unlocked_parakeet:
			current_speed_mod += 0.25
		
		current_speed_mod = max(0.1, current_speed_mod) # Limite que impede a velocidade de ser 0 ou negativa
		
		var final_speed = get_node("/root/Game").growing_speed * current_speed_mod
		flower_progress -= final_speed * delta
		
		update_visual_vase()
		
		if flower_progress <= 0:
			flower_progress = 0
			# Tenta fazer a colheita automática assim que a planta amadurecer
			check_auto_harvest()

func _pressed():
	# SE A FLOR ESTÁ PRONTA (Tempo <= 0) -> COLHER
	if flower_progress <= 0:
		var game = get_node("/root/Game")
		var base_gold = game.sell_value
		
		var value_mod = 1.0
		var quality_mod = 0.0
		var luck_mod = 0.0
		
		var adjacents = get_adjacents()
		
		# --- sistema adjacente: VALOR, QUALIDADE E SORTE ---
		if current_type == Element.Fire:
			for adj in adjacents:
				if adj.current_type == Element.Earth: quality_mod += 0.25
				if adj.current_type == Element.Air: luck_mod += 0.5
		
		elif current_type == Element.Earth:
			for adj in adjacents:
				if adj.current_type == Element.Fire: value_mod -= 0.25
				if adj.current_type == Element.Air: luck_mod -= 0.25
		
		elif current_type == Element.Water:
			for adj in adjacents:
				if adj.current_type == Element.Fire: value_mod -= 0.25
				if adj.current_type == Element.Earth: quality_mod += 0.50
		
		elif current_type == Element.Air:
			for adj in adjacents:
				if adj.current_type == Element.Fire: value_mod += 0.50
				if adj.current_type == Element.Earth: quality_mod -= 0.25

		if current_type == Element.Fire and game.unlocked_salamander:
			value_mod += 0.25
		elif current_type == Element.Earth and game.unlocked_armadillo:
			value_mod += 0.25
		elif current_type == Element.Water and game.unlocked_ray:
			value_mod += 0.25
		elif current_type == Element.Air and game.unlocked_parakeet:
			value_mod += 0.25

		value_mod = max(0.1, value_mod)
		quality_mod = max(0.0, quality_mod)
		luck_mod = max(0.0, luck_mod)

		# --- A MATEMÁTICA DA COLHEITA ---
		var total_essences = 1
		var final_quality_chance = base_quality_chance + (quality_mod * 100)
		if (randf() * 100) <= final_quality_chance:
			total_essences += 1
			
		var final_value_per_essence = (base_sell_value * value_mod) + base_gold
		var total_gold = final_value_per_essence * total_essences

		var is_crit = false
		var final_luck_chance = base_luck_chance + (luck_mod * 100)
		
		if (randf() * 100) <= final_luck_chance:
			total_gold *= 2 
			is_crit = true
			print("CRÍTICO! Ouro dobrado!")

# --- NOVO: APLICA O BÔNUS GLOBAL AQUI ---
		# Multiplica o ouro da planta pelo nível de prestígio do jogador
		total_gold = int(total_gold * game.global_gold_multiplier)

		# --- FEEDBACK VISUAL E ECONOMIA ---
		spawn_inting_text(total_gold, is_crit)
		
		game.add_gold(total_gold)
		flower_progress = base_growing_speed 
		update_visual_vase()

# SE A FLOR AINDA ESTÁ CRESCENDO (Tempo > 0) -> REGAR (ACELERAR)
	else:
		var game = get_node("/root/Game")
		
		var tempo_antigo = flower_progress
		flower_progress -= game.irrigation_bonus
		
		if flower_progress < 0:
			flower_progress = 0
			
		# Anima a descida do tempo de forma inteligente
		var tween = create_tween()
		tween.tween_method(
			func(tempo_atual): 
				if int(tempo_atual) <= 0:
					text = "HARVEST TIME!"
				else:
					text = "Growing: " + str(int(tempo_atual)) + "s", 
			tempo_antigo, 
			flower_progress, 
			0.3
		)
		update_visual_vase()

func get_adjacents():
	var adjacents = []
	var my_slot = get_parent()
	var container = my_slot.get_parent() 
	var my_index = my_slot.get_index()
	var cols = container.columns
	var checks = [my_index - cols, my_index + cols, my_index - 1, my_index + 1]
	
	for idx in checks:
		if idx >= 0 and idx < container.get_child_count():
			if abs(my_index % cols - idx % cols) <= 1:
				var neighbor_slot = container.get_child(idx)
				if neighbor_slot.get_child_count() > 0:
					adjacents.append(neighbor_slot.get_child(0)) 
	return adjacents

func update_visual_vase():
	if flower_progress <= 0:
		text = "HARVEST TIME!"
	else:
		text = "Growing: " + str(int(flower_progress)) + "s"
		
func spawn_inting_text(amount: int, is_critical: bool):
	var inting_text = Label.new()
	inting_text.text = "+" + str(amount)
	
	inting_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inting_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inting_text.position = Vector2(0, -25) 
	
	if is_critical:
		inting_text.text = "CRIT!\n" + inting_text.text
		inting_text.modulate = Color.GOLD 
		inting_text.scale = Vector2(1.5, 1.5)
	else:
		inting_text.modulate = Color.WHITE 
		
	add_child(inting_text)
	
	var tween = create_tween()
	tween.tween_property(inting_text, "position", inting_text.position + Vector2(0, -75), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(inting_text, "modulate:a", 0.0, 1.0)
	tween.tween_callback(inting_text.queue_free)

func check_auto_harvest():
	var game = get_node("/root/Game")
	var should_harvest = false
	
	# Verifica se o elemento atual tem a habilidade de auto-coleta desbloqueada
	if current_type == Element.Fire and game.auto_collect_fire:
		should_harvest = true
	elif current_type == Element.Earth and game.auto_collect_earth:
		should_harvest = true
	elif current_type == Element.Water and game.auto_collect_water:
		should_harvest = true
	elif current_type == Element.Air and game.auto_collect_air:
		should_harvest = true
		
	# Se tiver a habilidade, nós chamamos a função do clique manualmente!
	if should_harvest:
		_pressed()
