extends Button
class_name Flower

var flower_cost: int
var flower_progress: float
var base_growing_speed: int 
var base_sell_value: int 
var base_quality_chance: int 
var is_infested: bool = false
var pest_warning_label: Label = null # NOVO: Guarda o texto flutuante da praga

enum Element {Fire, Earth, Water, Air, Lava, Vapor, Plasma, Mud, Sand, Ice} 

var current_type = Element.Fire
var flower_sprite: TextureRect
var timer_label: Label

# --- REMOVIDA A SORTE DO DICIONÁRIO ---
const FLOWER_DATA = {
	Element.Fire: {
		"speed": 120, "value": 200, "quality": 25, "color": Color("#ff0000"),
		"sprites": [
			preload("res://Sprites/finalfp1.png"), 
			preload("res://Sprites/finalfp2.png"),
			preload("res://Sprites/finalfp3.png")
		]
	},
	Element.Earth: {
		"speed": 180, "value": 125, "quality": 50, "color": Color("#6aa84f")
	},
	Element.Water: {
		"speed": 90, "value": 150, "quality": 25, "color": Color("#4a86e8"),
		"sprites": [
			preload("res://Sprites/finalwp1.png"), 
			preload("res://Sprites/finalwp2.png"),
			preload("res://Sprites/finalwp3.png")
		]
	},
	Element.Air: {
		"speed": 120, "value": 150, "quality": 25, "color": Color("#ffcc00")
	},
	Element.Lava: {
		"speed": 270, "value": 3000, "quality": 75, "color": Color("#7e0306")
	},
	Element.Vapor: {
		"speed": 210, "value": 4000, "quality": 50, "color": Color("#ead1dc")
	},
	Element.Plasma: {
		"speed": 240, "value": 3000, "quality": 50, "color": Color("#8e7cc3")
	},
	Element.Mud: {
		"speed": 240, "value": 2500, "quality": 75, "color": Color("#38761d")
	},
	Element.Sand: {
		"speed": 270, "value": 4000, "quality": 75, "color": Color("#f9cb9c")
	},
	Element.Ice: {
		"speed": 210, "value": 3000, "quality": 50, "color": Color("#00ffff")
	}
}

func configure_flower(element_type):
	current_type = element_type
	if not FLOWER_DATA.has(current_type):
		print("ERRO: Status do elemento não encontrados no Dicionário!")
		return
		
	var data = FLOWER_DATA[current_type]
	base_growing_speed = data["speed"]
	base_sell_value = data["value"]
	base_quality_chance = data["quality"]
	
	flower_progress = base_growing_speed
	modulate = Color.WHITE 
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	var hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0, 0, 0, 0.15)
	
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
	for child in get_children():
		if child is Label:
			child.queue_free()

	flower_sprite = TextureRect.new()
	flower_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	flower_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	flower_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flower_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
	flower_sprite.offset_left = 0
	flower_sprite.offset_right = 0
	flower_sprite.offset_bottom = 0
	flower_sprite.offset_top = -40
	
	add_child(flower_sprite)
	
	timer_label = Label.new()
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	timer_label.offset_top = 5
	timer_label.offset_right = -8
	timer_label.add_theme_constant_override("outline_size", 4)
	timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(timer_label)
	
	text = "" 
	update_visual_vase()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	
func get_current_stats() -> Dictionary:
	var game = get_node("/root/Game")
	var adj_time_mod = 0.0
	var adj_value_mod = 0.0
	var adj_quality_mod = 0.0
	
	var affecting = get_affecting_flowers() 
	for data in affecting:
		var adj = data["flower"]
		var dx = data["dx"]
		var dy = data["dy"]
		var dist = data["dist"]
		var adj_type = adj.current_type
		
		var effectiveness = 1.0
		if dist > 1 and (current_type == Element.Water or adj_type == Element.Water):
			effectiveness = 0.5
			
		match adj_type:
			Element.Fire:
				if current_type == Element.Water: adj_value_mod -= (0.50 * effectiveness)
				elif current_type == Element.Air: adj_value_mod += (0.50 * effectiveness)
			Element.Earth:
				if current_type == Element.Water: adj_quality_mod += (0.50 * effectiveness)
				elif current_type == Element.Air: adj_quality_mod -= (0.50 * effectiveness)
			Element.Water:
				if current_type == Element.Fire: adj_time_mod += (0.50 * effectiveness) # (+)Tempo = Pior
				elif current_type == Element.Earth: adj_time_mod -= (0.50 * effectiveness) # (-)Tempo = Melhor
			Element.Lava:
				if dx == dy: # Diagonais
					adj_value_mod += (0.50 * effectiveness)
					adj_quality_mod += (0.50 * effectiveness)
					if current_type == Element.Water: adj_time_mod += (0.50 * effectiveness)
			Element.Vapor:
				if dx == dy:
					adj_time_mod -= (0.75 * effectiveness)
					if current_type == Element.Earth: adj_quality_mod -= (0.50 * effectiveness)
			Element.Plasma:
				if dx <= 1 and dy <= 1:
					adj_value_mod += (0.50 * effectiveness)
			Element.Mud:
				if dx == dy:
					adj_quality_mod += (1.0 * effectiveness)
					adj_time_mod += (0.50 * effectiveness)
			Element.Sand:
				if dx <= 1 and dy <= 1: 
					adj_time_mod += (0.50 * effectiveness) # Imediatamente adjacente = Debuff
				else: 
					adj_quality_mod += (0.75 * effectiveness) # Anel externo = Buff
			Element.Ice:
				if dy == 0: # Linha Horizontal
					adj_time_mod -= (1.0 * effectiveness)
				elif dx == 0: # Coluna Vertical
					if current_type == Element.Earth: adj_quality_mod -= (0.50 * effectiveness)
					elif current_type == Element.Fire: adj_value_mod -= (0.50 * effectiveness)

	var step1_time = base_growing_speed + (base_growing_speed * adj_time_mod)
	var step1_value = base_sell_value + (base_sell_value * adj_value_mod)
	var step1_quality = base_quality_chance + (base_quality_chance * adj_quality_mod)
	
	step1_time = max(base_growing_speed * 0.1, step1_time)
	step1_value = max(0, step1_value)
	step1_quality = max(base_quality_chance * 0.1, step1_quality)
	
	var mult_time = 1.0
	var mult_value = 1.0 
	
	# Verifica quais elementos estão contidos na flor atual
	var has_fire = current_type in [Element.Fire, Element.Lava, Element.Vapor, Element.Plasma]
	var has_earth = current_type in [Element.Earth, Element.Lava, Element.Mud, Element.Sand]
	var has_water = current_type in [Element.Water, Element.Vapor, Element.Mud, Element.Ice]
	var has_air = current_type in [Element.Air, Element.Plasma, Element.Sand, Element.Ice]

	# Animais afetam as fusões que contêm seus elementos!
	if has_fire and game.unlocked_salamander:
		mult_time -= 0.25; mult_value += 0.25
	if has_earth and game.unlocked_armadillo:
		mult_time -= 0.25; mult_value += 0.25
	if has_water and game.unlocked_ray:
		mult_time -= 0.25; mult_value += 0.25
	if has_air and game.unlocked_parakeet:
		mult_time -= 0.25; mult_value += 0.25
		
	# Estações afetam as fusões que contêm seus elementos! (Gera a matemática perfeita do +25%)
	match game.current_season:
		game.Season.Summer:
			if has_fire: mult_time -= 0.50; mult_value -= 0.25
			if has_water: mult_time += 0.25; mult_value += 0.50
		game.Season.Autumn:
			if has_earth: mult_time -= 0.50; mult_value -= 0.25
			if has_air: mult_time += 0.25; mult_value += 0.50
		game.Season.Winter:
			if has_water: mult_time -= 0.50; mult_value -= 0.25
			if has_fire: mult_time += 0.25; mult_value += 0.50
		game.Season.Spring:
			if has_air: mult_time -= 0.50; mult_value -= 0.25
			if has_earth: mult_time += 0.25; mult_value += 0.50

	var final_time = step1_time * max(0.1, mult_time) # Trava de segurança no 10% mantida
	
	# Aplica a Redução em % da Árvore de Power Ups:
	var time_reduction = max(0.05, 1.0 - (game.growing_speed_level * 0.05))
	final_time = final_time * time_reduction
	
	# Aplica o bônus do evento caso ativo
	final_time /= game.mana_storm_multiplier
	
	var final_value = (step1_value + game.sell_value) * max(0.1, mult_value)
	var final_quality = step1_quality
	
	return {
		"time": final_time,
		"value": int(final_value),
		"quality": final_quality
	}

func _process(delta):
	# NOVA REGRA: A barra de tempo só esvazia se NÃO estiver infestada
	if flower_progress > 0 and not is_infested:
		var game = get_node("/root/Game")
		var stats = get_current_stats()
		
		# Remova o '* game.growing_speed' daqui. Fica só assim:
		var tick_speed = base_growing_speed / stats["time"] if stats["time"] > 0 else 1.0
		
		flower_progress -= tick_speed * delta
		update_visual_vase()
		
		if flower_progress <= 0:
			flower_progress = 0
			check_auto_harvest()

func _do_harvest():
	var game = get_node("/root/Game")
	var stats = get_current_stats() 
	
	var total_essences = 1
	var final_quality_chance = stats["quality"]
	
	total_essences += int(final_quality_chance / 100) 
	var leftover_quality = int(final_quality_chance) % 100 
	if (randf() * 100) <= leftover_quality:
		total_essences += 1
			
	var total_gold = stats["value"] * total_essences 
	total_gold = int(total_gold * game.global_gold_multiplier)

	spawn_inting_text(total_gold, total_essences) # Agora mandamos as Essências para desenhar os Red Crits!
	game.add_gold(total_gold)
	game.record_gold_yield(current_type, total_gold)
	
	flower_progress = base_growing_speed 
	update_visual_vase()

func _on_mouse_entered(): get_node("/root/Game").show_flower_tooltip(self)
func _on_mouse_exited(): get_node("/root/Game").hide_flower_tooltip()

func _pressed():
	var game = get_node("/root/Game")
	
	if is_infested:
		is_infested = false
		update_visual_vase() 
		if pest_warning_label != null:
			pest_warning_label.queue_free()
			pest_warning_label = null
		return
		
	if game.using_shovel:
		game.using_shovel = false 
		get_parent().remove_child(self) 
		queue_free() 
		game.highlight_empty_slots()
		game.update_ui()
		game.call_deferred("update_all_flowers_visuals")
		return
		
	if flower_progress <= 0:
		_do_harvest() 
	else:
		# Agora o clique reduz uma porcentagem do TEMPO BASE da planta!
		flower_progress -= float(base_growing_speed) * game.irrigation_bonus
		
		if flower_progress <= 0: 
			flower_progress = 0
		update_visual_vase()

# --- NOVO SISTEMA DE ALCANCE EMPILHÁVEL (SOPRO POLINIZADO) ---
func get_affecting_flowers() -> Array:
	var affecting = []
	var my_slot = get_parent()
	if not my_slot: return []
	var container = my_slot.get_parent()
	var cols = container.columns
	var my_idx = my_slot.get_index()
	var my_x = my_idx % cols
	var my_y = my_idx / cols
	
	for i in range(container.get_child_count()):
		if i == my_idx: continue
		var other_slot = container.get_child(i)
		if other_slot.get_child_count() > 1:
			var other_flower = other_slot.get_child(1)
			var dx = abs((i % cols) - my_x)
			var dy = abs((i / cols) - my_y)
			var dist = dx + dy
			
			var o_type = other_flower.current_type
			var rng = other_flower.get_buff_range()
			var hits_me = false
			
			# Lógica Geométrica das Auras
			if o_type in [Element.Fire, Element.Earth, Element.Water, Element.Air]:
				hits_me = (dx == 0 or dy == 0) and dist <= rng # Cruz (+)
			elif o_type in [Element.Lava, Element.Vapor, Element.Mud]:
				hits_me = (dx == dy) and dx > 0 and dx <= rng # Diagonais (X)
			elif o_type == Element.Plasma:
				hits_me = (dx <= 1 and dy <= 1) # Área 3x3
			elif o_type == Element.Sand:
				hits_me = (dx <= 2 and dy <= 2) # Anel
				if rng > 1: hits_me = (dx <= 3 and dy <= 3) # Interação com Flor de Ar expande o anel
			elif o_type == Element.Ice:
				hits_me = (dx == 0 or dy == 0) # Linha Inteira (Cross Map)
				
			if hits_me:
				affecting.append({"flower": other_flower, "dist": dist, "dx": dx, "dy": dy})
				
	return affecting

func get_buff_range() -> int:
	if current_type == Element.Plasma: return 1 # Imune ao sopro de Ar
	
	var base_range = 1
	var my_slot = get_parent()
	if not my_slot: return 1
	var container = my_slot.get_parent()
	var cols = container.columns
	var my_index = my_slot.get_index()
	
	var air_count = 0
	
	# Conta QUANTOS ventos estão imediatamente encostados em mim
	for i in range(container.get_child_count()):
		if i == my_index: continue
		var other_slot = container.get_child(i)
		if other_slot.get_child_count() > 1 and is_in_cross_range(my_index, i, cols, 1):
			var other_flower = other_slot.get_child(1)
			if other_flower.current_type == Element.Air:
				air_count += 1
					
	if air_count > 0:
		if current_type == Element.Fire or current_type == Element.Water:
			base_range += air_count # Sopro empilha aumento de alcance
		elif current_type == Element.Earth:
			base_range -= air_count # Sopro empilha redução de alcance
			
	return max(0, base_range)

func is_in_cross_range(idx1: int, idx2: int, cols: int, max_range: int) -> bool:
	if max_range <= 0: return false
	var x1 = idx1 % cols
	var y1 = idx1 / cols
	var x2 = idx2 % cols
	var y2 = idx2 / cols
	
	if x1 == x2: return abs(y1 - y2) <= max_range
	elif y1 == y2: return abs(x1 - x2) <= max_range
	return false

func get_cross_distance(idx1: int, idx2: int, cols: int) -> int:
	var x1 = idx1 % cols
	var y1 = idx1 / cols
	var x2 = idx2 % cols
	var y2 = idx2 / cols
	return abs(x1 - x2) + abs(y1 - y2)

func update_visual_vase():
	var style = get_theme_stylebox("normal").duplicate()
	var progress_percent = 0.0
	if base_growing_speed > 0: progress_percent = flower_progress / float(base_growing_speed)
		
	var current_stage = 0
	if progress_percent > 0.66: current_stage = 0 
	elif progress_percent > 0.33: current_stage = 1 
	else: current_stage = 2 
		
	if flower_sprite:
		var has_valid_sprite = false 
		if FLOWER_DATA.has(current_type) and FLOWER_DATA.get(current_type).has("sprites"):
			var sprites = FLOWER_DATA[current_type]["sprites"]
			if sprites.size() > current_stage and sprites[current_stage] != null:
				flower_sprite.texture = sprites[current_stage]
				flower_sprite.modulate = Color.WHITE
				has_valid_sprite = true 
				
		if not has_valid_sprite:
			var img_size = 128
			var img = Image.create_empty(img_size, img_size, false, Image.FORMAT_RGBA8)
			img.fill(Color.TRANSPARENT) 
			var square_size = 32
			var pos_x = (img_size - square_size) / 2
			var pos_y = (img_size - square_size) / 2
			img.fill_rect(Rect2i(pos_x, pos_y, square_size, square_size), Color.WHITE)
			var temp_tex = ImageTexture.create_from_image(img)
			flower_sprite.texture = temp_tex
			flower_sprite.modulate = FLOWER_DATA[current_type]["color"]
			
	if timer_label != null: 
		if flower_progress <= 0:
			timer_label.text = "HARVEST!"
			style.border_width_bottom = 0; style.border_width_top = 0
			style.border_width_left = 0; style.border_width_right = 0
			style.bg_color = Color(1.0, 0.84, 0.0, 0.4) 
		else:
			var game = get_node("/root/Game")
			var stats = get_current_stats() 
			
			# Remova a parte que multiplica por game.growing_speed
			var tick_speed = float(base_growing_speed) / stats["time"] if stats["time"] > 0 else 1.0
			var real_seconds_left = flower_progress / tick_speed if tick_speed > 0 else flower_progress
			
			timer_label.text = "%.1fs" % real_seconds_left
			style.border_width_bottom = 0; style.border_width_top = 0
			style.border_width_left = 0; style.border_width_right = 0
			style.bg_color = Color.TRANSPARENT
			
	text = ""
	add_theme_stylebox_override("normal", style)
		
# --- NOVO VISUAL DOS CRÍTICOS VERMELHOS (Baseado em Essências Drops) ---
func spawn_inting_text(amount: int, essences: int):
	var inting_text = Label.new()
	inting_text.text = "+" + str(amount)
	
	inting_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inting_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	inting_text.position = Vector2(0, -25) 
	inting_text.add_theme_constant_override("outline_size", 4)
	inting_text.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Hierarquia de Qualidade (Críticos Estilo Path of Exile)
	if essences >= 3:
		inting_text.text = "RED CRIT!\n" + inting_text.text
		inting_text.modulate = Color("#ff3333") # Vermelho Escuro
		inting_text.scale = Vector2(1.8, 1.8)
	elif essences == 2:
		inting_text.text = "CRIT!\n" + inting_text.text
		inting_text.modulate = Color.GOLD 
		inting_text.scale = Vector2(1.4, 1.4)
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
	if current_type == Element.Fire and game.fire_collecting_level > 0: should_harvest = true
	elif current_type == Element.Earth and game.earth_collecting_level > 0: should_harvest = true
	elif current_type == Element.Water and game.water_collecting_level > 0: should_harvest = true
	elif current_type == Element.Air and game.air_collecting_level > 0: should_harvest = true
	if should_harvest: _do_harvest()

func check_interaction_with(adj_type) -> int:
	# Retorna 1 se o vizinho der buff bom PRA GENTE ou receber da gente, e -1 se for ruim
	if current_type == Element.Fire:
		if adj_type == Element.Water: return -1
		if adj_type == Element.Air: return 1 # O Ar buffa nosso alcance
	elif current_type == Element.Earth:
		if adj_type == Element.Water: return 1
		if adj_type == Element.Air: return -1 # O Ar quebra nosso alcance
	elif current_type == Element.Water:
		if adj_type == Element.Fire: return -1
		if adj_type == Element.Earth: return 1
		if adj_type == Element.Air: return 1 # O Ar buffa nosso alcance
	elif current_type == Element.Air:
		if adj_type == Element.Fire: return 1 # O Fogo buffa nosso valor
		if adj_type == Element.Earth: return -1 # A Terra debuffa nossa qualidade
	return 0

func update_buff_visuals():
	for child in get_children():
		if child is Label and child.name.begins_with("BuffInd_"):
			remove_child(child) # Tira da árvore imediatamente para o has_node() funcionar!
			child.queue_free()

	var my_slot = get_parent()
	if not my_slot: return
	var container = my_slot.get_parent()
	if not container: return
	var cols = container.columns
	var my_index = my_slot.get_index()

	var affecting = get_affecting_flowers() 
	
	for data in affecting:
		var adj_flower = data["flower"]
		var interaction = check_interaction_with(adj_flower.current_type)
		
		if interaction != 0:
			var other_slot = adj_flower.get_parent()
			var other_index = other_slot.get_index()
			var x1 = my_index % cols; var y1 = my_index / cols
			var x2 = other_index % cols; var y2 = other_index / cols
			
			var dir = ""
			if x2 < x1: dir = "left"
			elif x2 > x1: dir = "right"
			elif y2 < y1: dir = "top"
			elif y2 > y1: dir = "bottom"
			
			if dir != "" and not has_node("BuffInd_" + dir):
				create_indicator(dir, interaction)

func create_indicator(dir: String, interaction: int):
	var ind = Label.new()
	ind.name = "BuffInd_" + dir
	ind.text = "+" if interaction == 1 else "-"
	ind.modulate = Color("#93c47d") if interaction == 1 else Color("#e06666")
	
	ind.add_theme_constant_override("outline_size", 4)
	ind.add_theme_color_override("font_outline_color", Color.BLACK)
	ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ind.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	var margin = 2
	if dir == "top": ind.vertical_alignment = VERTICAL_ALIGNMENT_TOP; ind.position.y += margin
	elif dir == "bottom": ind.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM; ind.position.y -= margin
	elif dir == "left": ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT; ind.position.x += margin
	elif dir == "right": ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT; ind.position.x -= margin

	add_child(ind)

func infest_flower():
	is_infested = true
	flower_sprite.modulate = Color("#800080") # Deixa a planta roxa/doente
	print("Uma planta foi infestada!")
	
	# Cria o texto persistente de aviso
	if pest_warning_label == null:
		pest_warning_label = Label.new()
		pest_warning_label.text = " PEST! "
		pest_warning_label.modulate = Color("#ff3333") # Vermelho alerta
		pest_warning_label.add_theme_constant_override("outline_size", 5)
		pest_warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
		
		pest_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		pest_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Coloca um pouco acima da planta
		pest_warning_label.position = Vector2(0, -30) 
		
		# Faz o texto ficar um pouco maior
		pest_warning_label.scale = Vector2(1.2, 1.2)
		
		add_child(pest_warning_label)
		
		# Cria uma animação em LOOP para o texto ficar subindo e descendo
		var tween = pest_warning_label.create_tween().set_loops()
		tween.tween_property(pest_warning_label, "position:y", -45.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(pest_warning_label, "position:y", -30.0, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
