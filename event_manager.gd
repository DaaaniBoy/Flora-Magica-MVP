extends Node

var event_timer: Timer

func _ready():
	event_timer = Timer.new()
	event_timer.wait_time = 120.0 # BALANCEAMENTO: Rola os dados a cada 2 minutos (120s)
	event_timer.autostart = true
	event_timer.timeout.connect(_on_event_timer_timeout)
	add_child(event_timer)

func _on_event_timer_timeout():
	var game = get_node("/root/Game")
	
	# --- TRAVA DE SEGURANÇA: Checa se já tem alguma praga rolando ---
	var has_active_pest = false
	var grid = game.get_node("GridContainer")
	if grid:
		for slot in grid.get_children():
			if slot.get_child_count() > 1:
				var flower = slot.get_child(1)
				if flower.is_infested:
					has_active_pest = true
					break # Já achou uma praga, não precisa checar o resto

	# 1. Rola a Praga (Só rola se NÃO tiver nenhuma praga ativa no momento!)
	if not has_active_pest:
		# BALANCEAMENTO: Chance base caiu para 20%. O Upgrade tira 3% por nível.
		var pest_chance = 0.20 - (game.protection_magic_level * 0.03) 
		if randf() <= pest_chance:
			spawn_pest(game)
	
	# 2. Rola a Joaninha (Pode rolar mesmo se tiver praga)
	if game.unlocked_golden_ladybug:
		var ladybug_chance = 0.10 + (game.ladybug_infestation_level * 0.08)
		if randf() <= ladybug_chance:
			spawn_golden_ladybug(game)
			
	# 3. Rola a Tempestade de Mana (Pode rolar mesmo se tiver praga)
	if game.unlocked_mana_storm:
		var storm_chance = 0.10 + (game.blue_clouds_level * 0.08)
		if randf() <= storm_chance:
			spawn_mana_cloud(game)

func spawn_pest(game):
	var grid = game.get_node("GridContainer")
	var active_flowers = []
	
	for slot in grid.get_children():
		if slot.get_child_count() > 1:
			var flower = slot.get_child(1)
			if not flower.is_infested:
				active_flowers.append(flower)
				
	if active_flowers.size() > 0:
		# Escolhe uma flor aleatória para infestar
		var target = active_flowers[randi() % active_flowers.size()]
		target.infest_flower()

func spawn_mana_cloud(game):
	var cloud = Button.new()
	cloud.text = "MANA CLOUD"
	cloud.custom_minimum_size = Vector2(100, 64)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#4a86e8") # Azul da água/mana
	style.corner_radius_top_left = 32; style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32; style.corner_radius_bottom_right = 32
	cloud.add_theme_stylebox_override("normal", style)
	
	var grid = game.get_node("GridContainer")
	var grid_pos = grid.global_position
	var grid_size = grid.size
	
	# Faz a nuvem nascer voando um pouco "acima" do jardim
	cloud.global_position = Vector2(randf_range(grid_pos.x, grid_pos.x + grid_size.x - 128), grid_pos.y - 80)
	
	if game.has_node("CanvasLayer"): game.get_node("CanvasLayer").add_child(cloud)
	else: game.add_child(cloud)
		
	# QUANDO CLICA: Chove e ativa o Buff!
	cloud.pressed.connect(func():
		game.activate_mana_storm()
		cloud.queue_free()
	)
	
	# Tempo de fuga (Some depois de 6 segundos se não for clicada)
	var death_timer = get_tree().create_timer(6.0)
	death_timer.timeout.connect(func():
		if is_instance_valid(cloud):
			var tween = cloud.create_tween()
			tween.tween_property(cloud, "modulate:a", 0.0, 0.5)
			tween.tween_callback(cloud.queue_free)
	)

func spawn_golden_ladybug(game):
	var ladybug = Button.new()
	ladybug.text = "LADYBUG"
	ladybug.custom_minimum_size = Vector2(100, 64)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.GOLD
	style.corner_radius_top_left = 32; style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32; style.corner_radius_bottom_right = 32
	ladybug.add_theme_stylebox_override("normal", style)
	
	var grid = game.get_node("GridContainer")
	var grid_pos = grid.global_position
	var grid_size = grid.size
	
	ladybug.global_position = Vector2(randf_range(grid_pos.x, grid_pos.x + grid_size.x - 128), randf_range(grid_pos.y, grid_pos.y + grid_size.y - 128))
	
	if game.has_node("CanvasLayer"): game.get_node("CanvasLayer").add_child(ladybug)
	else: game.add_child(ladybug)
		
	# QUANDO CLICA: Ativa o Buff de Ouro Passivo!
	ladybug.pressed.connect(func():
		game.activate_ladybug_buff()
		ladybug.queue_free()
	)
	
	var death_timer = get_tree().create_timer(5.0)
	death_timer.timeout.connect(func():
		if is_instance_valid(ladybug):
			var tween = ladybug.create_tween()
			tween.tween_property(ladybug, "modulate:a", 0.0, 0.5)
			tween.tween_callback(ladybug.queue_free)
	)
	
