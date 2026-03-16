extends Button

class_name Flor

var flower_cost: int
var flower_progress: float
var base_growing_speed: int 
var base_sell_value: int 
var base_quality_chance: int 
var base_luck_chance: int 
enum Element {Fire, Earth, Water, Air} 

var current_type = Element.Fire

func configure_flower(element_type):
	current_type = element_type
	
	base_growing_speed = 0 
	base_sell_value = 0
	base_quality_chance = 0
	base_luck_chance = 0
	
	var flower_color = Color.WHITE
	
	match current_type:
		Element.Fire: 
			flower_progress = 120
			base_growing_speed = 120 
			base_sell_value = 200 
			base_quality_chance = 25 
			base_luck_chance = 25    
			flower_color = Color("#ff0000")
		Element.Earth: 
			flower_progress = 180
			base_growing_speed = 180 
			base_sell_value = 125 
			base_quality_chance = 50 
			base_luck_chance = 25    
			flower_color = Color("#6aa84f")
		Element.Water: 
			flower_progress = 90
			base_growing_speed = 90 
			base_sell_value = 150 
			base_quality_chance = 25 
			base_luck_chance = 25    
			flower_color = Color("#4a86e8")
		Element.Air: 
			flower_progress = 120
			base_growing_speed = 120 
			base_sell_value = 150 
			base_quality_chance = 25 
			base_luck_chance = 50 
			flower_color = Color("#ff9900")
	
	flower_progress = base_growing_speed
	
	modulate = Color.WHITE 
	
	var style = StyleBoxFlat.new()
	style.bg_color = flower_color
	
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = flower_color.darkened(0.15) 
	
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", hover_style)
	add_theme_stylebox_override("pressed", hover_style)
	add_theme_stylebox_override("disabled", style)
	
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", Color.WHITE) 
	add_theme_constant_override("outline_size", 4)
	add_theme_color_override("font_outline_color", Color.BLACK)
	
	update_visual_vase()

func _ready():
	update_visual_vase()

func _process(delta):
	if flower_progress > 0:
		var current_speed_mod = 1.0
		var adjacents = get_adjacents()
		
		if current_type == Element.Fire:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod -= 0.50 
		elif current_type == Element.Earth:
			for adj in adjacents:
				if adj.current_type == Element.Water:
					current_speed_mod += 0.50 
		
		#Buff unlocked animal
		var game = get_node("/root/Game")
		if current_type == Element.Fire and game.unlocked_salamander:
			current_speed_mod += 0.25
		elif current_type == Element.Earth and game.unlocked_armadillo:
			current_speed_mod += 0.25
		elif current_type == Element.Water and game.unlocked_ray:
			current_speed_mod += 0.25
		elif current_type == Element.Air and game.unlocked_parakeet:
			current_speed_mod += 0.25
		
		match game.current_season:
			game.Season.Summer:
				if current_type == Element.Fire: current_speed_mod += 0.30
				elif current_type == Element.Water: current_speed_mod -= 0.15
			game.Season.Autumn:
				if current_type == Element.Earth: current_speed_mod += 0.30
				elif current_type == Element.Air: current_speed_mod -= 0.15
			game.Season.Winter:
				if current_type == Element.Water: current_speed_mod += 0.30
				elif current_type == Element.Fire: current_speed_mod -= 0.15
			game.Season.Spring:
				if current_type == Element.Air: current_speed_mod += 0.30
				elif current_type == Element.Earth: current_speed_mod -= 0.15
		
		current_speed_mod = max(0.1, current_speed_mod) 
		
		var final_speed = game.growing_speed * current_speed_mod
		flower_progress -= final_speed * delta
		
		update_visual_vase()
		
		if flower_progress <= 0:
			flower_progress = 0
			check_auto_harvest()

func _do_harvest():
	var game = get_node("/root/Game")
	var base_gold = game.sell_value
		
	var value_mod = 1.0
	var quality_mod = 0.0
	var luck_mod = 0.0
		
	var adjacents = get_adjacents()
		
	# Adjacent buff/debuff
	if current_type == Element.Fire:
		for adj in adjacents:
			if adj.current_type == Element.Air: luck_mod += 0.50 
	elif current_type == Element.Earth:
		for adj in adjacents:
			if adj.current_type == Element.Air: luck_mod -= 0.50 
	elif current_type == Element.Water:
		for adj in adjacents:
			if adj.current_type == Element.Fire: value_mod -= 0.50 
			if adj.current_type == Element.Earth: quality_mod += 0.50 
	elif current_type == Element.Air:
		for adj in adjacents:
			if adj.current_type == Element.Fire: value_mod += 0.50 
			if adj.current_type == Element.Earth: quality_mod -= 0.50
		
	# season buff/debuff (CORRIGIDO: Removido de dentro do elif do Ar)
	match game.current_season:
		game.Season.Summer:
			if current_type == Element.Fire: value_mod -= 0.15
			elif current_type == Element.Water: value_mod += 0.30
		game.Season.Autumn:
			if current_type == Element.Earth: value_mod -= 0.15
			elif current_type == Element.Air: value_mod += 0.30
		game.Season.Winter:
			if current_type == Element.Water: value_mod -= 0.15
			elif current_type == Element.Fire: value_mod += 0.30
		game.Season.Spring:
			if current_type == Element.Air: value_mod -= 0.15
			elif current_type == Element.Earth: value_mod += 0.30

	# Buff unlocked animal (CORRIGIDO: Removido de dentro do elif do Ar)
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

	total_gold = int(total_gold * game.global_gold_multiplier)

	spawn_inting_text(total_gold, is_crit)
		
	game.add_gold(total_gold)
	flower_progress = base_growing_speed 
	update_visual_vase()


func _pressed():
	var game = get_node("/root/Game")
	
	# --- LÓGICA DA PÁ DE JARDIM ---
	if game.using_shovel:
		game.using_shovel = false 
		get_parent().remove_child(self) 
		queue_free() 
		game.highlight_empty_slots()
		game.update_ui()
		return
		
	# SE A FLOR ESTÁ PRONTA (Tempo <= 0) -> COLHER
	if flower_progress <= 0:
		_do_harvest() # <--- CORRIGIDO: Nome da função atualizado
	else: # <--- CORRIGIDO: Mantido apenas um bloco else
		# LÓGICA DE IRRIGAÇÃO
		var tempo_antigo = flower_progress
		flower_progress -= game.irrigation_bonus
		
		if flower_progress < 0:
			flower_progress = 0
			
		var tween = create_tween()
		tween.tween_method(
			func(tempo_atual): 
				if int(tempo_atual) <= 0:
					text = "HARVEST\nTIME!"
				else:
					text = "Growing:\n" + str(int(tempo_atual)) + "s", 
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
		text = "HARVEST\nTIME!"
	else:
		text = "Growing:\n" + str(int(flower_progress)) + "s"
		
func spawn_inting_text(amount: int, is_critical: bool):
	var inting_text = Label.new()
	inting_text.text = "+" + str(amount)
	
	inting_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inting_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inting_text.position = Vector2(0, -25) 
	
	inting_text.add_theme_constant_override("outline_size", 4)
	inting_text.add_theme_color_override("font_outline_color", Color.BLACK)
	
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
	
	if current_type == Element.Fire and game.fire_collecting_level > 0:
		should_harvest = true
	elif current_type == Element.Earth and game.earth_collecting_level > 0:
		should_harvest = true
	elif current_type == Element.Water and game.water_collecting_level > 0:
		should_harvest = true
	elif current_type == Element.Air and game.air_collecting_level > 0:
		should_harvest = true
		
	if should_harvest:
		_do_harvest()
