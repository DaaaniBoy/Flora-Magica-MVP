extends Control

@onready var Flower_list = $MarginContainer/ScrollContainer/FlowerList
@onready var close_button = $CloseButton

func _ready():
	close_button.pressed.connect(_on_close_pressed)
	hide() # Começa invisível

func _on_close_pressed():
	hide()

# Esta função será chamada pelo game.gd para abrir e atualizar a lista
func open_encyclopedia():
	update_list()
	show()

func update_list():
	for child in Flower_list.get_children():
		child.queue_free()
		
	var title = Label.new()
	title.text = "--- Botanic Encyclopedia ---\n"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Flower_list.add_child(title)
	
	for element_key in Flower.FLOWER_DATA.keys():
		var data = Flower.FLOWER_DATA[element_key]
		if data == null: continue
		var element_name = Flower.Element.keys()[element_key]
		
		var card = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		margin.add_theme_constant_override("margin_right", 15)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 30) 
		
		var icon_node 
		
		if data.has("sprites") and data["sprites"].size() >= 3 and data["sprites"][2] != null:
			icon_node = TextureRect.new()
			# Espaço de 64x64 atua como uma moldura limpa para a sua arte de 32x32
			icon_node.custom_minimum_size = Vector2(64, 64)
			icon_node.texture = data["sprites"][2]
			icon_node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		else:
			icon_node = ColorRect.new()
			icon_node.custom_minimum_size = Vector2(64, 64)
			icon_node.color = data.get("color", Color.WHITE)
		
		var info_label = RichTextLabel.new()
		info_label.bbcode_enabled = true
		info_label.fit_content = true
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL 
		
		# --- A CORREÇÃO MÁGICA ---
		# Força o texto a ter pelo menos 450px de largura, impedindo que o Godot o esprema!
		info_label.custom_minimum_size = Vector2(500, 0)
		
		var text = "[b]Flower of " + element_name + "[/b]\n"
		text += "Growing Speed: " + str(data["speed"]) + "s | Sell Value: " + str(data["value"]) + "\n"
		text += "Quality of Harvest: " + str(data["quality"]) + "% | Cultivator's Lucky: " + str(data["luck"]) + "%\n"
		
		var ally = ""
		var enemy = ""
		match element_key:
			Flower.Element.Fire:
				ally = "[color=#93c47d]Air (+ Cultivator's Lucky)[/color]"
				enemy = "[color=#e06666]Water (- Growing Speed)[/color]"
			Flower.Element.Earth:
				ally = "[color=#93c47d]Water (+ Growing Speed)[/color]"
				enemy = "[color=#e06666]Air (- Cultivator's Lucky)[/color]"
			Flower.Element.Water:
				ally = "[color=#93c47d]Earth (+ Quality of Harvest)[/color]"
				enemy = "[color=#e06666]Fire (- Sell Value)[/color]"
			Flower.Element.Air:
				ally = "[color=#93c47d]Fire (+ Sell Value)[/color]"
				enemy = "[color=#e06666]Earth (- Quality of Harvest)[/color]"
				
		text += "Neighbor Synergy: " + ally + " vs " + enemy
		
		info_label.text = text
		
		hbox.add_child(icon_node)
		hbox.add_child(info_label)
		margin.add_child(hbox)
		card.add_child(margin)
		Flower_list.add_child(card)

	# --- SLOTS MISTERIOSOS ---
	for i in range(6):
		var card = PanelContainer.new()
		var margin = MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 15)
		margin.add_theme_constant_override("margin_top", 15)
		margin.add_theme_constant_override("margin_bottom", 15)
		margin.add_theme_constant_override("margin_right", 15)
		
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 30)
		
		var icon_node = ColorRect.new()
		icon_node.custom_minimum_size = Vector2(64, 64)
		icon_node.color = Color(0.1, 0.1, 0.1) # Um cinza bem escuro para parecer "bloqueado"
		icon_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST 
		
		var info_label = RichTextLabel.new()
		info_label.bbcode_enabled = true
		info_label.fit_content = true
		info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Aplica a mesma regra de tamanho largo para os slots misteriosos
		info_label.custom_minimum_size = Vector2(450, 0)
		
		info_label.text = "\n[center][b]?????[/b]\nKeep cultivating to discover more elemental Flowers...[/center]"
		
		hbox.add_child(icon_node)
		hbox.add_child(info_label)
		margin.add_child(hbox)
		card.add_child(margin)
		Flower_list.add_child(card)
