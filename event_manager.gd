extends Node

var event_timer: Timer
var ladybug_spawn_chance = 0.35 # 35% de chance de aparecer

func _ready():
	# Configura o cronômetro do Diretor de Eventos
	event_timer = Timer.new()
	event_timer.wait_time = 60.0 # Tenta rolar os dados a cada 60 segundos
	event_timer.autostart = true
	event_timer.timeout.connect(_on_event_timer_timeout)
	add_child(event_timer)

func _on_event_timer_timeout():
	if randf() <= ladybug_spawn_chance:
		spawn_golden_ladybug()

func spawn_golden_ladybug():
	# Referência ao jogo principal para podermos dar o ouro
	var game = get_node("/root/Game")
	
	var ladybug = Button.new()
	ladybug.text = "🐞!"
	ladybug.custom_minimum_size = Vector2(64, 64)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color.GOLD
	style.corner_radius_top_left = 32
	style.corner_radius_top_right = 32
	style.corner_radius_bottom_left = 32
	style.corner_radius_bottom_right = 32
	ladybug.add_theme_stylebox_override("normal", style)
	ladybug.add_theme_stylebox_override("hover", style)
	ladybug.add_theme_stylebox_override("pressed", style)
	ladybug.add_theme_color_override("font_color", Color.BLACK)
	
# --- NOVO: LIMITANDO A APARIÇÃO AO GRID DO JARDIM ---
	var grid = game.get_node("GridContainer")
	
	# Pega o ponto de origem (canto superior esquerdo) e o tamanho total do Grid
	var grid_pos = grid.global_position
	var grid_size = grid.size
	
	# Sorteia uma posição X e Y que comece no início do Grid e vá até o final dele.
	# Subtraímos 64 (o tamanho da joaninha) no final para garantir que ela não "vaze" para fora da borda direita/inferior.
	var random_x = randf_range(grid_pos.x, grid_pos.x + grid_size.x - 128)
	var random_y = randf_range(grid_pos.y, grid_pos.y + grid_size.y - 128)
	
	# Usamos global_position em vez de position para ela nascer no lugar exato da tela
	ladybug.global_position = Vector2(random_x, random_y)
	
	# Coloca no CanvasLayer do Game para ficar por cima da UI
	if game.has_node("CanvasLayer"):
		game.get_node("CanvasLayer").add_child(ladybug)
	else:
		game.add_child(ladybug)
		
	# Lógica do Clique (Recompensa)
	ladybug.pressed.connect(func():
		var base_reward = 500
		var reward = int((base_reward + (game.sell_value * 10)) * game.global_gold_multiplier)
		game.add_gold(reward) # Chama a função de ouro lá do game.gd!
		
		var float_text = Label.new()
		float_text.text = "+" + str(reward) + " GOLD!"
		float_text.modulate = Color.GOLD
		float_text.position = ladybug.position
		float_text.add_theme_constant_override("outline_size", 4)
		float_text.add_theme_color_override("font_outline_color", Color.BLACK)
		ladybug.get_parent().add_child(float_text)
		
		var tween = create_tween()
		tween.tween_property(float_text, "position:y", float_text.position.y - 50, 1.0)
		tween.parallel().tween_property(float_text, "modulate:a", 0.0, 1.0)
		tween.tween_callback(float_text.queue_free)
		
		ladybug.queue_free()
	)
	
	# Lógica de Fuga
	var death_timer = get_tree().create_timer(4.5)
	death_timer.timeout.connect(func():
		if is_instance_valid(ladybug):
			var tween = create_tween()
			tween.tween_property(ladybug, "modulate:a", 0.0, 0.5)
			tween.tween_callback(ladybug.queue_free)
)
