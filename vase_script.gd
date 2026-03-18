extends Button
class_name Flower

var flower_cost: int
var flower_progress: float
var base_growing_speed: int 
var base_sell_value: int 
var base_quality_chance: int 
var base_luck_chance: int 

# ATENÇÃO: Para o futuro, já adicionei as Fusões no Enum. 
# Você precisará atualizar o Enum no game.gd para ficar idêntico a este!
enum Element {Fire, Earth, Water, Air, Lava, Vapor, Plasma, Mud, Sand, Ice} 

var current_type = Element.Fire
var flower_sprite: TextureRect
var timer_label: Label

# --- O NOSSO DICIONÁRIO DE DADOS ---
# Aqui ficam guardados todos os status base do GDD. 
# Se precisar balancear o jogo depois, você só mexe aqui!
const FLOWER_DATA = {
	Element.Fire: {
		"speed": 120, "value": 200, "quality": 25, "luck": 25, "color": Color("#ff0000")
	},
	Element.Earth: {
		"speed": 150, "value": 125, "quality": 50, "luck": 25, "color": Color("#6aa84f")
	},
	Element.Water: {
		"speed": 90, "value": 150, "quality": 25, "luck": 25, "color": Color("#4a86e8"),
		"sprites": [
			preload("res://Sprites/waterplant1.png"), 
			preload("res://Sprites/waterplant2.png"),
			preload("res://Sprites/waterplant3.png")
		]
	},
	Element.Air: {
		"speed": 120, "value": 150, "quality": 25, "luck": 50, "color": Color("#ff9900")
	}
	# --- EXEMPLO DE COMO ADICIONAR AS FUSÕES DEPOIS ---
	# Basta descomentar e ajustar os valores conforme o GDD quando for implementar:
	# Element.Lava: {
	# 	"speed": 300, "value": 3000, "quality": 75, "luck": 50, "color": Color("#ff6600")
	# },
}

func configure_flower(element_type):
	current_type = element_type
	
	# Verifica se o elemento existe no nosso dicionário por segurança
	if not FLOWER_DATA.has(current_type):
		print("ERRO: Status do elemento não encontrados no Dicionário!")
		return
		
	# Puxa a "gaveta" inteira de dados do elemento escolhido
	var data = FLOWER_DATA[current_type]
	
	# Distribui os dados para as variáveis
	base_growing_speed = data["speed"]
	base_sell_value = data["value"]
	base_quality_chance = data["quality"]
	base_luck_chance = data["luck"]
	
	var flower_color = data["color"]
	
	flower_progress = base_growing_speed
	modulate = Color.WHITE 
	
	# --- PARTE VISUAL (Mantida igual a sua) ---
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
	flower_sprite = TextureRect.new()
	flower_sprite.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Deixei um pouco mais de espaço pro texto embaixo (-25)
	flower_sprite.offset_top = 5
	flower_sprite.offset_bottom = -25 
	flower_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	flower_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	flower_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
	
	add_child(flower_sprite)
	
	# --- CORREÇÃO DA ÂNCORA DO TEXTO ---
	timer_label = Label.new()
	timer_label.set_anchors_preset(Control.PRESET_FULL_RECT) # Ocupa o botão todo
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM # Joga o texto pro chão
	
	timer_label.add_theme_constant_override("outline_size", 4)
	timer_label.add_theme_color_override("font_outline_color", Color.BLACK)
	add_child(timer_label)
	
	# ISSO AQUI MATA O TEXTO ORIGINAL FANTASMA
	text = "" 
	
	update_visual_vase()
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

# --- NOVA FUNÇÃO CENTRAL DE MATEMÁTICA ---
func get_current_modifiers() -> Dictionary:
	var game = get_node("/root/Game")
	var speed_mod = 1.0
	var value_mod = 1.0
	var quality_mod = 0.0
	var luck_mod = 0.0
	
	var adjacents = get_adjacents()
	
	# Adjacency buff/debuff
	if current_type == Element.Fire:
		for adj in adjacents:
			if adj.current_type == Element.Water: speed_mod -= 0.50 
			if adj.current_type == Element.Air: luck_mod += 0.50 
	elif current_type == Element.Earth:
		for adj in adjacents:
			if adj.current_type == Element.Water: speed_mod += 0.50 
			if adj.current_type == Element.Air: luck_mod -= 0.50 
	elif current_type == Element.Water:
		for adj in adjacents:
			if adj.current_type == Element.Fire: value_mod -= 0.50 
			if adj.current_type == Element.Earth: quality_mod += 0.50 
	elif current_type == Element.Air:
		for adj in adjacents:
			if adj.current_type == Element.Fire: value_mod += 0.50 
			if adj.current_type == Element.Earth: quality_mod -= 0.50
			
	# Buff unlocked animal
	if current_type == Element.Fire and game.unlocked_salamander:
		speed_mod += 0.50
		value_mod += 0.25
	elif current_type == Element.Earth and game.unlocked_armadillo:
		speed_mod += 0.50
		value_mod += 0.25
	elif current_type == Element.Water and game.unlocked_ray:
		speed_mod += 0.50
		value_mod += 0.25
	elif current_type == Element.Air and game.unlocked_parakeet:
		speed_mod += 0.50
		value_mod += 0.25
		
	# Season buff/debuff
	match game.current_season:
		game.Season.Summer:
			if current_type == Element.Fire:
				speed_mod += 0.50; value_mod -= 0.15
			elif current_type == Element.Water:
				speed_mod -= 0.25; value_mod += 0.30
		game.Season.Autumn:
			if current_type == Element.Earth:
				speed_mod += 0.50; value_mod -= 0.15
			elif current_type == Element.Air:
				speed_mod -= 0.25; value_mod += 0.30
		game.Season.Winter:
			if current_type == Element.Water:
				speed_mod += 0.50; value_mod -= 0.15
			elif current_type == Element.Fire:
				speed_mod -= 0.25; value_mod += 0.30
		game.Season.Spring:
			if current_type == Element.Air:
				speed_mod += 0.50; value_mod -= 0.15
			elif current_type == Element.Earth:
				speed_mod -= 0.25; value_mod += 0.30
				
	return {
		"speed_mod": max(0.1, speed_mod),
		"value_mod": max(0.1, value_mod),
		"quality_mod": max(-1.0, quality_mod), # CORRIGIDO: Agora permite ficar negativo
		"luck_mod": max(-1.0, luck_mod)        # CORRIGIDO: Agora permite ficar negativo
	}

# --- PROCESS LIMPO E DIRETO ---
func _process(delta):
	if flower_progress > 0:
		var game = get_node("/root/Game")
		var mods = get_current_modifiers()
		
		var final_speed = game.growing_speed * mods["speed_mod"]
		flower_progress -= final_speed * delta
		
		update_visual_vase()
		
		if flower_progress <= 0:
			flower_progress = 0
			check_auto_harvest()

# --- HARVEST LIMPO E DIRETO ---
func _do_harvest():
	var game = get_node("/root/Game")
	var mods = get_current_modifiers()
	
	# --- SISTEMA DE MULTIDROP (QUALIDADE) ---
	var total_essences = 1
	var final_quality_chance = base_quality_chance * (1.0 + mods["quality_mod"])
	
	total_essences += int(final_quality_chance / 100) # Ex: 230% dá +2 inteiros
	var leftover_quality = int(final_quality_chance) % 100 # Pega o resto (30)
	if (randf() * 100) <= leftover_quality:
		total_essences += 1
			
	# DEPOIS: O Buff agora multiplica o poder base JUNTO com os seus upgrades!
	var final_value_per_essence = (base_sell_value + game.sell_value) * mods["value_mod"]
	var total_gold = final_value_per_essence * total_essences

	# --- SISTEMA DE MULTI-CRIT (SORTE) ---
	var is_crit = false
	var final_luck_chance = base_luck_chance * (1.0 + mods["luck_mod"])
	var crit_multiplier = 1 + int(final_luck_chance / 100) # Ex: 230% baseia o dano em x3
	var leftover_luck = int(final_luck_chance) % 100
	
	if (randf() * 100) <= leftover_luck:
		crit_multiplier += 1 
		
	if crit_multiplier > 1:
		total_gold *= crit_multiplier
		is_crit = true

	total_gold = int(total_gold * game.global_gold_multiplier)

	spawn_inting_text(total_gold, is_crit)
	game.add_gold(total_gold)
	game.record_gold_yield(current_type, total_gold)
	
	flower_progress = base_growing_speed 
	update_visual_vase()

# --- ATUALIZAMOS O HOVER PARA MANDAR A flower INTEIRA ---
func _on_mouse_entered():
	var game = get_node("/root/Game")
	game.show_flower_tooltip(self) # Enviamos a própria flower e não só os dados crus

func _on_mouse_exited():
	var game = get_node("/root/Game")
	game.hide_flower_tooltip()

func _pressed():
	var game = get_node("/root/Game")
	
	# --- LÓGICA DA PÁ DE JARDIM ---
	if game.using_shovel:
		game.using_shovel = false 
		get_parent().remove_child(self) 
		queue_free() 
		game.highlight_empty_slots()
		game.update_ui()
		game.call_deferred("update_all_flowers_visuals")
		return
		
	# SE A flower ESTÁ PRONTA (Tempo <= 0) -> COLHER
	if flower_progress <= 0:
		_do_harvest() 
	else:
		# LÓGICA DE IRRIGAÇÃO (Limpamos o Tween para não travar)
		flower_progress -= game.irrigation_bonus
		
		if flower_progress <= 0:
			flower_progress = 0
			
		update_visual_vase() # Atualiza instantaneamente, sem brigar com o _process

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
	var style = get_theme_stylebox("normal").duplicate()
	
	# Previne erro matemático no exato frame em que a flor nasce
	var progress_percent = 0.0
	if base_growing_speed > 0:
		progress_percent = flower_progress / float(base_growing_speed)
		
	var current_stage = 0
	
	if progress_percent > 0.66:
		current_stage = 0 # Broto
	elif progress_percent > 0.33:
		current_stage = 1 # Média
	else:
		current_stage = 2 # Grande
		
	if flower_sprite and FLOWER_DATA.has(current_type) and FLOWER_DATA.get(current_type).has("sprites"):
		var sprites = FLOWER_DATA[current_type]["sprites"]
		if sprites.size() > current_stage and sprites[current_stage] != null:
			flower_sprite.texture = sprites[current_stage]
	
	# ... (Lógica das sprites continua igual)
	
	if flower_progress <= 0:
		timer_label.text = "HARVEST!" # Simplificamos para caber perfeito e não vazar
		style.border_width_bottom = 10
		style.border_width_top = 10
		style.border_width_left = 10
		style.border_width_right = 10
		style.border_color = Color.GOLD
	else:
		var game = get_node("/root/Game")
		var mods = get_current_modifiers()
		var final_speed_mult = game.growing_speed * mods["speed_mod"]
		var real_seconds_left = flower_progress / final_speed_mult if final_speed_mult > 0 else flower_progress
		
		# Escreve o tempo direto no nosso Label fixo
		timer_label.text = str(ceil(real_seconds_left)) + "s"
		
		style.border_width_bottom = 0
		style.border_width_top = 0
		style.border_width_left = 0
		style.border_width_right = 0
		
	if FLOWER_DATA.has(current_type):
		style.bg_color = FLOWER_DATA[current_type]["color"].darkened(0.75)
		
	# MATA O TEXTO ORIGINAL DE NOVO POR SEGURANÇA
	text = ""
	
	add_theme_stylebox_override("normal", style)
		
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

# --- SISTEMA DE INDICADORES VISUAIS DE ADJACÊNCIA ---

func check_interaction_with(adj_type) -> int:
	# Retorna 1 para Buff, -1 para Debuff e 0 para Neutro
	if current_type == Element.Fire:
		if adj_type == Element.Water: return -1
		if adj_type == Element.Air: return 1
	elif current_type == Element.Earth:
		if adj_type == Element.Water: return 1
		if adj_type == Element.Air: return -1
	elif current_type == Element.Water:
		if adj_type == Element.Fire: return -1
		if adj_type == Element.Earth: return 1
	elif current_type == Element.Air:
		if adj_type == Element.Fire: return 1
		if adj_type == Element.Earth: return -1
	return 0

func update_buff_visuals():
	# 1. Limpa os indicadores antigos caso os vizinhos tenham mudado
	for child in get_children():
		if child is Label and child.name.begins_with("BuffInd_"):
			child.queue_free()

	var my_slot = get_parent()
	if not my_slot: return
	var container = my_slot.get_parent()
	if not container: return
	
	var my_index = my_slot.get_index()
	var cols = container.columns

	# Mapeia onde estão os vizinhos
	var checks = {
		"top": my_index - cols,
		"bottom": my_index + cols,
		"left": my_index - 1,
		"right": my_index + 1
	}

	for dir in checks.keys():
		var idx = checks[dir]
		# Se o slot existe no grid
		if idx >= 0 and idx < container.get_child_count():
			# Evita que a planta da ponta direita ache que é vizinha da ponta esquerda
			if (dir == "left" or dir == "right") and abs(my_index % cols - idx % cols) > 1:
				continue

			var neighbor_slot = container.get_child(idx)
			# Se tem uma planta naquele vizinho
			if neighbor_slot.get_child_count() > 0:
				var adj_flower = neighbor_slot.get_child(0)
				var interaction = check_interaction_with(adj_flower.current_type)
				
				# Se houver interação, desenha a setinha na direção do vizinho
				if interaction != 0:
					create_indicator(dir, interaction)

func create_indicator(dir: String, interaction: int):
	var ind = Label.new()
	ind.name = "BuffInd_" + dir
	# DICA: No futuro, você pode substituir esse Label por um TextureRect com seu Pixel Art!
	ind.text = "▲" if interaction == 1 else "▼"
	ind.modulate = Color("#93c47d") if interaction == 1 else Color("#e06666")
	
	ind.add_theme_constant_override("outline_size", 4)
	ind.add_theme_color_override("font_outline_color", Color.BLACK)
	
	ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ind.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Empurra a setinha para a borda correta
	var margin = 2
	if dir == "top":
		ind.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		ind.position.y += margin
	elif dir == "bottom":
		ind.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		ind.position.y -= margin
	elif dir == "left":
		ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ind.position.x += margin
	elif dir == "right":
		ind.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ind.position.x -= margin

	add_child(ind)
