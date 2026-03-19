extends Control

@onready var Flower_list = $MarginContainer/ScrollContainer/FlowerList
@onready var close_button = $CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hide() 

func _on_close_pressed():
	hide()

func open_encyclopedia():
	update_list()
	show()

func update_list():
	var game = get_node("/root/Game")
	
	for child in Flower_list.get_children():
		child.queue_free()
		
	var title = Label.new()
	title.text = "--- Botanic Encyclopedia ---\n"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Flower_list.add_child(title)
	
	var mystery_count = 0 # Contador de quantas plantas estão trancadas
	
	for element_key in Flower.FLOWER_DATA.keys():
		var data = Flower.FLOWER_DATA[element_key]
		if data == null: continue
		var element_name = Flower.Element.keys()[element_key]
		
		# --- VERIFICAÇÃO DE DESBLOQUEIO ---
		var is_unlocked = true
		match element_key:
			Flower.Element.Lava: is_unlocked = game.unlocked_alchemy_lava
			Flower.Element.Vapor: is_unlocked = game.unlocked_alchemy_vapor
			Flower.Element.Plasma: is_unlocked = game.unlocked_alchemy_plasma
			Flower.Element.Mud: is_unlocked = game.unlocked_alchemy_mud
			Flower.Element.Sand: is_unlocked = game.unlocked_alchemy_sand
			Flower.Element.Ice: is_unlocked = game.unlocked_alchemy_ice
			
		if not is_unlocked:
			mystery_count += 1
			continue # Pula a criação do card visível e vai para o próximo!
		
		var card = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		margin.add_theme_constant_override("margin_right", 15)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 30) 
		
		var icon_node 
		
		# --- CORREÇÃO DO TAMANHO DA IMAGEM ---
		if data.has("sprites") and data["sprites"].size() >= 3 and data["sprites"][2] != null:
			icon_node = TextureRect.new()
			icon_node.custom_minimum_size = Vector2(128, 128) # DOBRAMOS O TAMANHO!
			icon_node.texture = data["sprites"][2]
			icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			icon_node = ColorRect.new()
			icon_node.custom_minimum_size = Vector2(128, 128) # DOBRAMOS O TAMANHO!
			icon_node.color = data.get("color", Color.WHITE)
		
		var info_label = RichTextLabel.new()
		info_label.bbcode_enabled = true
		info_label.fit_content = true
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		info_label.custom_minimum_size = Vector2(500, 0)
		
		var text = "[b]Flower of " + element_name + "[/b]\n"
		text += "Growing Speed: " + str(data["speed"]) + "s | Sell Value: " + str(data["value"]) + "\n"
		text += "Quality of Harvest: " + str(data["quality"]) + "%\n"
		
		# Texto genérico de Sinergia (Pode ser melhorado depois buscando do Dictionary)
		text += "Synergy: See the manual for detailed interactions."
		
		info_label.text = text
		
		hbox.add_child(icon_node)
		hbox.add_child(info_label)
		margin.add_child(hbox)
		card.add_child(margin)
		Flower_list.add_child(card)

	# --- GERA EXATAMENTE OS SLOTS MISTERIOSOS QUE FALTAM ---
	for i in range(mystery_count):
		var card = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		margin.add_theme_constant_override("margin_right", 15)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 30)
		
		var icon_node = ColorRect.new()
		icon_node.custom_minimum_size = Vector2(128, 128) # Tamanho padronizado
		icon_node.color = Color(0.1, 0.1, 0.1) 
		icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
		
		var info_label = RichTextLabel.new()
		info_label.bbcode_enabled = true
		info_label.fit_content = true
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_label.custom_minimum_size = Vector2(450, 0)
		info_label.text = "\n[center][b]?????[/b]\nKeep cultivating to discover more elemental Flowers...[/center]"
		
		hbox.add_child(icon_node)
		hbox.add_child(info_label)
		margin.add_child(hbox)
		card.add_child(margin)
		Flower_list.add_child(card)
