extends Node

var event_timer: Timer

func _ready():
	event_timer = Timer.new()
	event_timer.wait_time =60.0 # Rola os dados a cada 60s
	event_timer.autostart = true
	event_timer.timeout.connect(_on_event_timer_timeout)
	add_child(event_timer)

func _on_event_timer_timeout():
	var game = get_node("/root/Game")
	
	# 1. Rola a Praga (Sempre pode acontecer, mas upgrades diminuem a chance)
	var pest_chance = 0.30 - (game.anti_plague_magic_level * 0.05) # Cai 5% por nível
	if randf() <= pest_chance:
		spawn_pest(game)
	
	# 2. Rola a Joaninha
	if game.unlocked_golden_ladybug:
		var ladybug_chance = 0.10 + (game.ladybug_infestation_level * 0.08)
		if randf() <= ladybug_chance:
			spawn_golden_ladybug(game)
			
	# 3. Rola a Tempestade de Mana
	if game.unlocked_mana_storm:
		var storm_chance = 0.15 # 15% fixo
		if randf() <= storm_chance:
			trigger_mana_storm(game)

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

func trigger_mana_storm(game):
	game.activate_mana_storm()

func spawn_golden_ladybug(game):
	var ladybug = Button.new()
	ladybug.text = "🐞"
	ladybug.custom_minimum_size = Vector2(64, 64)
	
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
			var tween = create_tween()
			tween.tween_property(ladybug, "modulate:a", 0.0, 0.5)
			tween.tween_callback(ladybug.queue_free)
	)
	
