extends Button
class_name Flor

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

# --- O NOSSO DICIONÁRIO DE DADOS ---
# Aqui ficam guardados todos os status base do GDD. 
# Se precisar balancear o jogo depois, você só mexe aqui!
const FLOWER_DATA = {
	Element.Fire: {
		"speed": 120, "value": 200, "quality": 25, "luck": 25, "color": Color("#ff0000")
	},
	Element.Earth: {
		"speed": 180, "value": 125, "quality": 50, "luck": 25, "color": Color("#6aa84f")
	},
	Element.Water: {
		"speed": 90, "value": 150, "quality": 25, "luck": 25, "color": Color("#4a86e8")
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
	update_visual_vase()
	
	# Conecta os sinais de hover do botão
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
		"quality_mod": max(0.0, quality_mod),
		"luck_mod": max(0.0, luck_mod)
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
	
	var total_essences = 1
	var final_quality_chance = base_quality_chance * (1.0 + mods["quality_mod"])
	if (randf() * 100) <= final_quality_chance:
		total_essences += 1
			
	var final_value_per_essence = (base_sell_value * mods["value_mod"]) + game.sell_value
	var total_gold = final_value_per_essence * total_essences

	var is_crit = false
	var final_luck_chance = base_luck_chance * (1.0 + mods["luck_mod"])
	if (randf() * 100) <= final_luck_chance:
		total_gold *= 2 
		is_crit = true

	total_gold = int(total_gold * game.global_gold_multiplier)

	spawn_inting_text(total_gold, is_crit)
	game.add_gold(total_gold)
	game.record_gold_yield(current_type, total_gold)
	
	flower_progress = base_growing_speed 
	update_visual_vase()

# --- ATUALIZAMOS O HOVER PARA MANDAR A FLOR INTEIRA ---
func _on_mouse_entered():
	var game = get_node("/root/Game")
	game.show_flower_tooltip(self) # Enviamos a própria flor e não só os dados crus

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
		return
		
	# SE A FLOR ESTÁ PRONTA (Tempo <= 0) -> COLHER
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
	var style = get_theme_stylebox("normal").duplicate() # Pega o estilo atual
	
	if flower_progress <= 0:
		text = "HARVEST\nTIME!"
		style.border_width_bottom = 10
		style.border_width_top = 10
		style.border_width_left = 10
		style.border_width_right = 10
		style.border_color = Color.GOLD
	else:
		var game = get_node("/root/Game")
		var mods = get_current_modifiers()
		var final_speed_mult = game.growing_speed * mods["speed_mod"]
		
		# A MÁGICA: Converte o progresso base em "segundos reais" baseados na velocidade atual
		var real_seconds_left = flower_progress / final_speed_mult if final_speed_mult > 0 else flower_progress
		
		# Usamos ceil() para arredondar para cima e não mostrar decimais
		text = "Growing:\n" + str(ceil(real_seconds_left)) + "s"
		
		style.border_width_bottom = 0
		style.border_width_top = 0
		style.border_width_left = 0
		style.border_width_right = 0
		
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
