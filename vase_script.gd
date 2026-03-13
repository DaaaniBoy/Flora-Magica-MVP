extends Button

enum Element {Water, Fire, Earth, Air}
var current_type = Element.Water 

# --- ATRIBUTOS BASE DA PLANTA ---
var plant_progress: float = 120.0
var base_time: float = 120.0 # Growing Speed Attribute
var base_value_multiplier: float = 1.0 # Sell Value Attribute
var base_quality_chance: float = 0.0 # Quality of Harvest Attribute
var base_luck_chance: float = 0.0    # Farmer's Luck Attribute

func configure_plant(element_type):
	current_type = element_type
	
	# Reseta os atributos para o padrão ANTES de aplicar a identidade
	base_time = 120.0 
	base_value_multiplier = 1.0 
	base_quality_chance = 0.0 
	base_luck_chance = 0.0 
	
	match current_type:
		Element.Water: # FAST
			base_time = 60.0
			modulate = Color("4a86e8")
		Element.Fire: # EXPENSIVE
			base_value_multiplier = 2.5 
			modulate = Color("#e06666")
		Element.Earth: # QUALITY
			base_quality_chance = 0.5
			modulate = Color("#6aa84f")
		Element.Air: # LUCK
			base_luck_chance = 0.2
			modulate = Color("#ff9900")
	
	plant_progress = base_time
	update_visual_vase()

func _ready():
	update_visual_vase()

func _process(delta):
	if plant_progress > 0:
		var current_speed_mod = 1.0
		var adjacents = get_adjacents()
		
		# --- AURA: VELOCIDADE ---
		if current_type == Element.Fire:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod -= 0.5 
		elif current_type == Element.Earth:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod += 0.5 
		
		current_speed_mod = max(0.1, current_speed_mod) #Limite que impede a velociade de ser 0 ou negativa
		
		var final_speed = get_node("/root/Game").growing_speed * current_speed_mod
		plant_progress -= final_speed * delta
		
		if plant_progress < 0:
			plant_progress = 0
		update_visual_vase()

func _pressed():
	if plant_progress <= 0:
		var game = get_node("/root/Game")
		var base_gold = game.essence_value
		
		var value_mod = 1.0
		var quality_mod = 0.0
		var luck_mod = 0.0
		
		var adjacents = get_adjacents()
		
		# --- AURAS: VALOR, QUALIDADE E SORTE ---
		# Usamos as variáveis locais (_mod) para não corromper o status base da planta
		if current_type == Element.Water:
			for adj in adjacents:
				if adj.current_type == Element.Fire: value_mod -= 0.5
				if adj.current_type == Element.Earth: quality_mod += 0.5
		
		elif current_type == Element.Fire:
			for adj in adjacents:
				if adj.current_type == Element.Air: luck_mod += 0.5
		
		elif current_type == Element.Earth:
			for adj in adjacents:
				if adj.current_type == Element.Air: luck_mod -= 0.5
		
		elif current_type == Element.Air:
			for adj in adjacents:
				if adj.current_type == Element.Fire: value_mod += 0.5
				if adj.current_type == Element.Earth: quality_mod -= 0.5

		value_mod = max(0.1, value_mod) # Nunca vale menos que 10% do valor
		quality_mod = max(0.0, quality_mod) # Qualidade nunca é negativa
		luck_mod = max(0.0, luck_mod) # Sorte nunca é negativa

		# --- A MATEMÁTICA DA COLHEITA ---
		
		# 1. Qualidade (Rendimento / total_essences)
		var total_essences = 1
		var final_quality_chance = base_quality_chance + quality_mod
		if randf() <= final_quality_chance:
			total_essences += 1
			
		# 2. Valor Final da Essência
		var final_value_per_essence = (base_gold * base_value_multiplier) * value_mod

		# 3. Calcular Ouro Total Base
		var total_gold = final_value_per_essence * total_essences

		# 4. Calcular Crítico (SORTE)
		var is_crit = false
		var final_luck_chance = base_luck_chance + luck_mod
		
		if randf() <= final_luck_chance:
			total_gold *= 2 
			is_crit = true
			print("CRÍTICO! Ouro dobrado!")

		# --- FEEDBACK VISUAL E ECONOMIA ---
		spawn_floating_text(int(total_gold), is_crit)
		
		# Entrega o ouro (substituí "add_gold" e "add_gold" pela função correta do seu game.gd)
		game.add_gold(int(total_gold))
		plant_progress = base_time 
		update_visual_vase()
	else:
		plant_progress -= get_node("/root/Game").irrigation_bonus
		if plant_progress < 0:
			plant_progress = 0
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
	if plant_progress <= 0:
		text = "HARVEST TIME!"
	else:
		text = "Growing: " + str(int(plant_progress)) + "s"
		
func spawn_floating_text(amount: int, is_critical: bool):
	var floating_text = Label.new()
	floating_text.text = "+" + str(amount)
	
	floating_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	floating_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	floating_text.position = Vector2(0, -20) 
	
	if is_critical:
		floating_text.text = "CRIT!\n" + floating_text.text
		floating_text.modulate = Color.ORANGE
		floating_text.scale = Vector2(1.2, 1.2)
	else:
		floating_text.modulate = Color.GOLD 
		
	add_child(floating_text)
	
	var tween = create_tween()
	tween.tween_property(floating_text, "position", floating_text.position + Vector2(0, -50), 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(floating_text, "modulate:a", 0.0, 1.0)
	tween.tween_callback(floating_text.queue_free)
