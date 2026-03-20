extends Node2D

var vase_texture = preload("res://Sprites/emptyvasef1.png")

enum Element {Fire, Earth, Water, Air, Lava, Vapor, Plasma, Mud, Sand, Ice}
enum Season {Summer, Autumn, Winter, Spring} 
var chosen_element = Element.Fire 
var current_season = Season.Summer 

# --- VARIÁVEIS DE FUSÃO ---
var unlocked_alchemy_lava: bool = false 
var unlocked_alchemy_vapor: bool = false
var unlocked_alchemy_plasma: bool = false
var unlocked_alchemy_mud: bool = false
var unlocked_alchemy_sand: bool = false
var unlocked_alchemy_ice: bool = false

var fusion_requirement: int = 1800 

var discovered_fusions = {
	Element.Lava: false, Element.Vapor: false, Element.Plasma: false,
	Element.Mud: false, Element.Sand: false, Element.Ice: false
}

var fusion_times = {
	Element.Lava: 0, Element.Vapor: 0, Element.Plasma: 0,
	Element.Mud: 0, Element.Sand: 0, Element.Ice: 0
}

var fusion_scanner: Timer

# Variáveis do GDD
var player_gold: int = 0
var displayed_gold: int = 0 
var gold_tween: Tween 
var total_accumulated_gold: int = 0 

var irrigation_bonus = 1.0 
var irrigation_bonus_level = 0
var irrigation_bonus_max_level = 30
var irrigation_increase_base_cost = 350

var growing_speed_level = 0 
var growing_speed_max_level = 19 
var growing_speed_increase_base_cost = 500

var mana_storm_multiplier = 1.0 

var sell_value = 0
var sell_value_level = 1
var sell_value_max_level = 30
var sell_value_base_cost = 750

var quality_chance_min = 0 
var quality_chance_max = 100 
var luck_chance_min = 0 
var luck_chance_max = 0 

var vase_scene = preload("res://Vase.tscn") 
var vase_level = 0
var vase_max_level = 25

var positioning_new_vase: bool = false 
var planting_seed: bool = false 
var is_first_free_vase: bool = false 
var seed_buy_count: int = 0 
var using_shovel: bool = false 

# Variáveis de Prestígio (GDD)
var magic_scrolls: int = 0
var prestige_count: int = 0
var global_gold_multiplier: float = 1.0 

# Habilidades de Prestígio - Ramo da Zoologia
var unlocked_salamander: bool = false
var unlocked_armadillo: bool = false       
var unlocked_ray: bool = false       
var unlocked_parakeet: bool = false  

var fire_collecting_level: int = 0
var earth_collecting_level: int = 0
var water_collecting_level: int = 0
var air_collecting_level: int = 0

var fire_specialist_level: int = 0
var earth_specialist_level: int = 0
var water_specialist_level: int = 0
var air_specialist_level: int = 0

# Produtores da Alquimia
var lava_producer_level: int = 0
var vapor_producer_level: int = 0
var plasma_producer_level: int = 0
var mud_producer_level: int = 0
var sand_producer_level: int = 0
var ice_producer_level: int = 0
var pure_extraction_level: int = 0 

# --- Habilidades de Prestígio - Ramo dos Eventos Naturais ---
var unlocked_golden_ladybug: bool = false 
var lasting_luck_level: int = 0
var ladybug_infestation_level: int = 0

var unlocked_mana_storm: bool = false
var mana_flood_level: int = 0
var blue_clouds_level: int = 0

var anti_plague_magic_level: int = 0
var protection_magic_level: int = 0

# --- VARIÁVEIS DE CONTROLE DE EVENTOS NATURAIS (RELOGIOS) ---
var ladybug_buff_time: float = 0.0
var mana_storm_time: float = 0.0

var ladybug_timer_ui: Label = null
var mana_storm_timer_ui: Label = null

var gold_yield = {
	Element.Fire: 0, Element.Earth: 0, Element.Water: 0, Element.Air: 0,
	Element.Lava: 0, Element.Vapor: 0, Element.Plasma: 0, Element.Mud: 0, Element.Sand: 0, Element.Ice: 0
}

var hovered_flower = null 

# ==========================================
# NOVOS CAMINHOS "RADAR" - NUNCA MAIS QUEBRAM!
# ==========================================
@onready var gold = find_child("Gold", true, false)
@onready var season_label = find_child("SeasonLabel", true, false)
@onready var grid = find_child("GridContainer", true, false)
@onready var total_gold_label = find_child("TotalGoldAccumulated", true, false)
@onready var magic_scrolls_label = find_child("MagicScrolls", true, false)
@onready var prestige_button = find_child("PrestigeButton", true, false)
@onready var skill_tree_button = find_child("SkillTreeButton", true, false)
@onready var plant_seed_button = find_child("PlantSeedButton", true, false) 
@onready var shovel_button = find_child("ShovelButton", true, false) 
@onready var encyclopedia_button = find_child("EncyclopediaButton", true, false)

# Botões de Upgrades que você moveu de lugar
@onready var btn_speed = find_child("GrowingSpeedIncrease", true, false)
@onready var btn_irrigation = find_child("IrrigationIncrease", true, false)
@onready var btn_sell = find_child("SellValueIncrese", true, false)
@onready var btn_buy_vase = find_child("BuyVaseButton", true, false)

# Novo texto tutorial dinâmico
@onready var tutorial_label = find_child("TutorialLabel", true, false)

# Menus no CanvasLayer (Estes não foram movidos, então continuam normais)
@onready var skill_tree_menu = $CanvasLayer/SkillTreeMenu 
@onready var hover_panel = $CanvasLayer/HoverPanel
@onready var yield_container = $CanvasLayer/YieldPanel/MarginContainer/YieldContainer
@onready var encyclopedia_menu = $CanvasLayer/EncyclopediaMenu
@onready var hover_label = hover_panel.find_child("RichTextLabel", true, false) if hover_panel else null


func build_grid():
	if not grid: return
	for slot in grid.get_children():
		grid.remove_child(slot)
		slot.queue_free()

	var grid_size = 3
	var slot_size = 140 
	
	if prestige_count == 1:
		grid_size = 4; slot_size = 100 
	elif prestige_count >= 2:
		grid_size = 5; slot_size = 75 
		
	grid.columns = grid_size
	vase_max_level = (grid_size * grid_size) - 1

	for i in range(grid_size * grid_size):
		var slot = Button.new()
		slot.custom_minimum_size = Vector2(slot_size, slot_size)
		slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		var vase_bg = TextureRect.new()
		vase_bg.name = "VaseBG"
		vase_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE 
		vase_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		vase_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		vase_bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		vase_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		vase_bg.offset_left = 0; vase_bg.offset_right = 0; vase_bg.offset_bottom = 0; vase_bg.offset_top = -40
		slot.add_child(vase_bg)
		
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.1)
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(1, 1, 1, 0.2)
		
		slot.add_theme_stylebox_override("normal", style)
		slot.add_theme_stylebox_override("hover", hover_style)
		slot.add_theme_stylebox_override("pressed", hover_style)
		slot.add_theme_stylebox_override("disabled", style)
		
		slot.set_meta("has_vase", false)
		grid.add_child(slot)
		slot.pressed.connect(_on_empty_slot_pressed.bind(slot))
		
func _ready():
	build_grid() 
	
	if btn_buy_vase:
		btn_buy_vase.modulate = Color("#ffffff")

	if encyclopedia_button and not encyclopedia_button.pressed.is_connected(_on_encyclopedia_button_pressed):
		encyclopedia_button.pressed.connect(_on_encyclopedia_button_pressed)
	if skill_tree_button and not skill_tree_button.pressed.is_connected(_on_skill_tree_button_pressed):
		skill_tree_button.pressed.connect(_on_skill_tree_button_pressed)

	is_first_free_vase = true
	positioning_new_vase = true 
	planting_seed = false
	highlight_empty_slots() 
	
	if season_label:
		season_label.meta_hover_started.connect(_on_season_hover_started)
		season_label.meta_hover_ended.connect(_on_season_hover_ended)
	
	if hover_panel:
		hover_panel.custom_minimum_size = Vector2(280, 0)
		var internal_margin_container = hover_panel.get_node_or_null("MarginContainer")
		if internal_margin_container:
			internal_margin_container.add_theme_constant_override("margin_top", 0)
			internal_margin_container.add_theme_constant_override("margin_bottom", 0)
			internal_margin_container.add_theme_constant_override("margin_left", 0)
			internal_margin_container.add_theme_constant_override("margin_right", 0)
		
		var panel_style_box = hover_panel.get_theme_stylebox("panel")
		if panel_style_box:
			var new_style_box = panel_style_box.duplicate()
			new_style_box.content_margin_top = 8; new_style_box.content_margin_bottom = 8
			new_style_box.content_margin_left = 10; new_style_box.content_margin_right = 10
			hover_panel.add_theme_stylebox_override("panel", new_style_box)
			
	fusion_scanner = Timer.new()
	fusion_scanner.wait_time = 1.0 
	fusion_scanner.autostart = true
	fusion_scanner.timeout.connect(_scan_for_fusions)
	add_child(fusion_scanner)

	# --- CONTADORES NA TELA DA UI ---
	ladybug_timer_ui = Label.new()
	ladybug_timer_ui.add_theme_constant_override("outline_size", 5)
	ladybug_timer_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	ladybug_timer_ui.modulate = Color("#ffd700") 
	ladybug_timer_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	ladybug_timer_ui.hide()
	# Âncora no Canto Inferior Esquerdo, empurrado 350px para a direita (para não cobrir o Ouro/Prestígio)
	ladybug_timer_ui.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	ladybug_timer_ui.offset_left = 350 
	ladybug_timer_ui.offset_top = -90 
	if has_node("CanvasLayer"): get_node("CanvasLayer").call_deferred("add_child", ladybug_timer_ui)

	mana_storm_timer_ui = Label.new()
	mana_storm_timer_ui.add_theme_constant_override("outline_size", 5)
	mana_storm_timer_ui.add_theme_color_override("font_outline_color", Color.BLACK)
	mana_storm_timer_ui.modulate = Color("#4a86e8") 
	mana_storm_timer_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	mana_storm_timer_ui.hide()
	mana_storm_timer_ui.hide()
	mana_storm_timer_ui.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	mana_storm_timer_ui.offset_left = 350
	mana_storm_timer_ui.offset_top = -60 # Fica logo abaixo da Joaninha!
	if has_node("CanvasLayer"): get_node("CanvasLayer").call_deferred("add_child", mana_storm_timer_ui)

	# --- CONECTANDO O HOVER DOS BOTÕES ---
	ladybug_timer_ui.mouse_entered.connect(_on_ladybug_timer_hovered)
	ladybug_timer_ui.mouse_exited.connect(_on_any_ui_unhovered)
	mana_storm_timer_ui.mouse_entered.connect(_on_mana_storm_timer_hovered)
	mana_storm_timer_ui.mouse_exited.connect(_on_any_ui_unhovered)

	if btn_speed:
		btn_speed.mouse_entered.connect(_on_upgrade_hovered.bind("speed"))
		btn_speed.mouse_exited.connect(_on_any_ui_unhovered)
	if btn_irrigation:
		btn_irrigation.mouse_entered.connect(_on_upgrade_hovered.bind("irrigation"))
		btn_irrigation.mouse_exited.connect(_on_any_ui_unhovered)
	if btn_sell:
		btn_sell.mouse_entered.connect(_on_upgrade_hovered.bind("sell"))
		btn_sell.mouse_exited.connect(_on_any_ui_unhovered)
		
	update_ui()

func calculating_upgrade_cost(base: float, multiplier: float, level: int) -> int:
	return roundi(base * pow(multiplier, level))

func format_number(value: float) -> String:
	if value >= 1_000_000_000: return "%.2fB" % (value / 1_000_000_000.0)
	elif value >= 1_000_000: return "%.2fM" % (value / 1_000_000.0)
	elif value >= 1_000: return "%.1fK" % (value / 1_000.0)
	else: return str(value)

func format_full_with_suffix(value: float) -> String:
	if value >= 1_000: return str(value) + " (" + format_number(value) + ")"
	return str(value)

# ==========================================
# LÓGICA DOS TOOLTIPS DE UPGRADES E EVENTOS
# ==========================================
func _on_upgrade_hovered(type: String):
	hovered_flower = null
	if not hover_panel or not hover_label: return
	hover_panel.show()
	var text = ""

	if type == "speed":
		var current = growing_speed_level * 5
		var next = (growing_speed_level + 1) * 5
		if growing_speed_level >= growing_speed_max_level:
			text = "[center][b]Growing Speed Upgrade[/b][/center]\nLevel MAX: Reduces " + str(current) + "% of the base growing time of all flowers."
		else:
			text = "[center][b]Growing Speed Upgrade[/b][/center]\nLevel " + str(growing_speed_level) + ": Reduces " + str(current) + "% of growing time.\n> [color=#008000]Level " + str(growing_speed_level + 1) + ": Reduces " + str(next) + "% of growing time.[/color]"

	elif type == "irrigation":
		var next = irrigation_bonus + 0.5
		if irrigation_bonus_level >= irrigation_bonus_max_level:
			text = "[center][b]Watering Can Upgrade[/b][/center]\nLevel MAX: Clicking reduces " + str(irrigation_bonus) + "s of growing time."
		else:
			text = "[center][b]Watering Can Upgrade[/b][/center]\nLevel " + str(irrigation_bonus_level) + ": Clicking reduces " + str(irrigation_bonus) + "s.\n> [color=#008000]Level " + str(irrigation_bonus_level + 1) + ": Clicking reduces " + str(next) + "s.[/color]"

	elif type == "sell":
		var next_inc = roundi(15 * pow(1.15, sell_value_level))
		var next_total = sell_value + next_inc
		if sell_value_level >= sell_value_max_level:
			text = "[center][b]Fertilizer Upgrade[/b][/center]\nLevel MAX: Adds +" + str(sell_value) + " Gold to the sell value of all flowers."
		else:
			text = "[center][b]Fertilizer Upgrade[/b][/center]\nLevel " + str(sell_value_level) + ": Adds +" + str(sell_value) + " Gold.\n> [color=#008000]Level " + str(sell_value_level + 1) + ": Adds +" + str(next_total) + " Gold.[/color]"

	hover_label.text = text
	hover_panel.size = Vector2.ZERO

func _on_ladybug_timer_hovered():
	hovered_flower = null
	if hover_panel and hover_label:
		hover_panel.show()
		hover_label.text = "[center][b]Golden Ladybug Buff[/b][/center]\n[color=#ffd700]Double Sell Value for all flowers![/color]"
		hover_panel.size = Vector2.ZERO

func _on_mana_storm_timer_hovered():
	hovered_flower = null
	if hover_panel and hover_label:
		hover_panel.show()
		var buff_power = 2.0 + (mana_flood_level * 0.5)
		hover_label.text = "[center][b]Mana Storm Buff[/b][/center]\n[color=#4a86e8]Growing Speed multiplied by " + str(buff_power) + "x![/color]"
		hover_panel.size = Vector2.ZERO

func _on_any_ui_unhovered():
	if hover_panel: hover_panel.hide()

# ==========================================
# ATUALIZAÇÃO DA TELA
# ==========================================
func update_ui():
	if season_label:
		match current_season:
			Season.Summer: season_label.text = "Season: [color=#ff0000]Summer[/color] (Fire is [url=abundant][color=gold][b]Abundant[/b][/color][/url] and Water is [url=rare][color=gold][b]Rare[/b][/color][/url])"
			Season.Autumn: season_label.text = "Season: [color=#6aa84f]Autumn[/color] (Earth is [url=abundant][color=gold][b]Abundant[/b][/color][/url] and Air is [url=rare][color=gold][b]Rare[/b][/color][/url])"
			Season.Winter: season_label.text = "Season: [color=#4a86e8]Winter[/color] (Water is [url=abundant][color=gold][b]Abundant[/b][/color][/url] and Fire is [url=rare][color=gold][b]Rare[/b][/color][/url])"
			Season.Spring: season_label.text = "Season: [color=#ff9900]Spring[/color] (Air is [url=abundant][color=gold][b]Abundant[/b][/color][/url] and Earth is [url=rare][color=gold][b]Rare[/b][/color][/url])"
				
	if gold_tween and gold_tween.is_running(): gold_tween.kill()
		
	gold_tween = create_tween()
	gold_tween.tween_method(
		func(valor_atual): 
			if gold:
				displayed_gold = valor_atual 
				gold.text = "Gold: " + format_full_with_suffix(valor_atual), 
		displayed_gold, 
		player_gold,   
		0.5             
	)
	
	if total_gold_label: total_gold_label.text = "Total Accumulated Gold: " + format_full_with_suffix(total_accumulated_gold)
	if magic_scrolls_label: magic_scrolls_label.text = "Magic Scrolls: " + str(magic_scrolls)

	# --- Atualiza Textos dos Upgrades Movidos ---
	if btn_speed:
		var reduction = growing_speed_level * 5
		if growing_speed_level >= growing_speed_max_level:
			btn_speed.text = "Lvl MAX |\nSpeed: -%d%%\nCost: MAX" % [reduction]
			btn_speed.disabled = true
		else:
			var speed_cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
			btn_speed.text = "Lvl %d/%d |\nSpeed: -%d%% -> -%d%%\nCost: %s Gold" % [growing_speed_level, growing_speed_max_level, reduction, reduction + 5, format_number(speed_cost)]
			btn_speed.disabled = false

	if btn_irrigation:
		if irrigation_bonus_level >= irrigation_bonus_max_level:
			btn_irrigation.text = "Lvl MAX |\nClick: -%.1fs\nCost: MAX" % [irrigation_bonus]
			btn_irrigation.disabled = true
		else:
			var irr_cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
			btn_irrigation.text = "Lvl %d/%d |\nClick: -%.1fs -> -%.1fs\nCost: %s Gold" % [irrigation_bonus_level, irrigation_bonus_max_level, irrigation_bonus, irrigation_bonus + 0.5, format_number(irr_cost)]
			btn_irrigation.disabled = false

	if btn_sell:
		if sell_value_level >= sell_value_max_level:
			btn_sell.text = "Lvl MAX |\nValue: +%s\nCost: MAX" % [format_number(sell_value)]
			btn_sell.disabled = true
		else:
			var sell_cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
			var next_sell_increment = roundi(15 * pow(1.15, sell_value_level)) 
			btn_sell.text = "Lvl %d/%d |\nValue: +%s -> +%s\nCost: %s Gold" % [sell_value_level, sell_value_max_level, format_number(sell_value), format_number(sell_value + next_sell_increment), format_number(sell_cost)]
			btn_sell.disabled = false

	if btn_buy_vase:
		if vase_level >= vase_max_level:
			btn_buy_vase.text = "Vases: MAX (%d/%d)" % [vase_level + 1, vase_max_level + 1]
			btn_buy_vase.disabled = true
		elif positioning_new_vase:
			btn_buy_vase.text = "Click on a locked space!"
			btn_buy_vase.disabled = true 
		else:
			var next_vase_cost = calculating_upgrade_cost(1000, 1.75, vase_level)
			btn_buy_vase.text = "New Vase: %d/%d\nCost: %s Gold" % [vase_level + 1, vase_max_level + 1, format_number(next_vase_cost)]
			btn_buy_vase.disabled = false

	if plant_seed_button:
		var active_flowers = 0
		if grid:
			for slot in grid.get_children():
				if slot.get_child_count() > 1: active_flowers += 1
				
		var total_vases = vase_level + 1
		
		if planting_seed:
			plant_seed_button.text = "Click on an empty vase!"
			plant_seed_button.disabled = false
		elif active_flowers >= total_vases:
			plant_seed_button.text = "All vases are full!"
			plant_seed_button.disabled = true
		else:
			var next_seed_cost = calculating_upgrade_cost(100, 1.10, seed_buy_count)
			plant_seed_button.text = "Plant Seed (%d/%d)\nCost: %s Gold" % [active_flowers, total_vases, format_number(next_seed_cost)]
			plant_seed_button.disabled = false

	if prestige_button:
		var target = get_prestige_target()
		if total_accumulated_gold >= target:
			prestige_button.disabled = false 
			prestige_button.modulate = Color.SKY_BLUE 
			prestige_button.text = "PRESTIGE READY!"
		else:
			prestige_button.disabled = true 
			prestige_button.modulate = Color.WHITE
			prestige_button.text = "Prestige (" + format_number(total_accumulated_gold) + " / " + format_number(target) + ")"

	if shovel_button:
		if using_shovel:
			shovel_button.text = "Click on a Flower to destroy it!"
			shovel_button.modulate = Color("#8fce00") 
		else:
			shovel_button.text = "Shovel (Remove Flower)"
			shovel_button.modulate = Color.WHITE

	# --- TUTORIAL DINÂMICO ---
	if tutorial_label:
		if is_first_free_vase:
			tutorial_label.text = "[center]Welcome to your magical garden! 🌱\nClick on an empty square to place your first Vase![/center]"
		elif positioning_new_vase:
			tutorial_label.text = "[center]Great! 🌻\nNow click on a locked slot in the garden to place your new Vase.[/center]"
		elif planting_seed:
			tutorial_label.text = "[center]Ready to plant! 💧\nSelect an Element below and click on an empty Vase.[/center]"
		elif using_shovel:
			tutorial_label.text = "[center]Shovel active! ⛏️\nClick on a flower to remove it.\n(Right-click to cancel)[/center]"
		else:
			tutorial_label.text = "[center]Select an Element and click 'Plant Seed' to grow a new flower!\n(Right-click cancels actions)[/center]"


func _on_season_hover_started(meta):
	hovered_flower = null
	if hover_panel:
		hover_panel.show()
		if str(meta) == "abundant":
			hover_label.text = "[center][b]Abundant Element[/b][/center]\n\n[color=#008000]+50%[/color] Growing Speed\n[color=#ff0000]-25%[/color] Sell Value"
		elif str(meta) == "rare":
			hover_label.text = "[center][b]Rare Element[/b][/center]\n\n[color=#ff0000]-25%[/color] Growing Speed\n[color=#008000]+50%[/color] Sell Value"
		hover_panel.size = Vector2.ZERO

func _on_season_hover_ended(meta):
	if hover_panel: hover_panel.hide()

func gain_gold():
	player_gold += int(sell_value)
	update_ui()

func _on_growing_speed_increase_pressed() -> void:
	if growing_speed_level < growing_speed_max_level:
		var cost = calculating_upgrade_cost(growing_speed_increase_base_cost, 1.5, growing_speed_level)
		if player_gold >= cost:
			player_gold -= cost; growing_speed_level += 1; update_ui()
			if hover_panel and hover_panel.visible: _on_upgrade_hovered("speed")

func _on_irrigation_increase_pressed() -> void:
	if irrigation_bonus_level < irrigation_bonus_max_level:
		var cost = calculating_upgrade_cost(irrigation_increase_base_cost, 1.5, irrigation_bonus_level)
		if player_gold >= cost:
			player_gold -= cost; irrigation_bonus_level += 1; irrigation_bonus += 0.5; update_ui()
			if hover_panel and hover_panel.visible: _on_upgrade_hovered("irrigation")

func _on_sell_value_increse_pressed() -> void:
	if sell_value_level < sell_value_max_level:
		var cost = calculating_upgrade_cost(sell_value_base_cost, 1.5, sell_value_level)
		if player_gold >= cost:
			player_gold -= cost
			var next_sell_increment = roundi(15 * pow(1.15, sell_value_level))
			sell_value += next_sell_increment; sell_value_level += 1; update_ui()
			if hover_panel and hover_panel.visible: _on_upgrade_hovered("sell")

func _on_buy_vase_button_pressed() -> void:
	if vase_level < vase_max_level:
		var cost = calculating_upgrade_cost(1000, 1.75, vase_level)
		if player_gold >= cost and not positioning_new_vase and not planting_seed:
			player_gold -= cost; vase_level += 1; positioning_new_vase = true
			highlight_empty_slots(); update_ui()

func _on_plant_seed_button_pressed() -> void:
	var cost = calculating_upgrade_cost(100, 1.5, seed_buy_count)
	if player_gold >= cost and not positioning_new_vase and not planting_seed:
		player_gold -= cost; planting_seed = true; seed_buy_count += 1
		highlight_empty_slots(); update_ui()

func _on_shovel_button_pressed() -> void:
	if is_first_free_vase: return
	if not using_shovel:
		if positioning_new_vase or planting_seed: cancel_actions()
		using_shovel = true
	else:
		using_shovel = false 
	highlight_empty_slots(); update_ui()

func _on_empty_slot_pressed(clicked_slot):
	if positioning_new_vase:
		if clicked_slot.get_meta("has_vase") == false:
			clicked_slot.set_meta("has_vase", true) 
			positioning_new_vase = false
			if is_first_free_vase: planting_seed = true
			highlight_empty_slots(); update_ui()
			
	elif planting_seed:
		if clicked_slot.get_meta("has_vase") == true and clicked_slot.get_child_count() == 1:
			var new_flower = vase_scene.instantiate()
			clicked_slot.add_child(new_flower)
			new_flower.clip_text = true 
			new_flower.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
			new_flower.custom_minimum_size = Vector2.ZERO 
			new_flower.size = clicked_slot.size 
			new_flower.set_anchors_preset(Control.PRESET_FULL_RECT)
			new_flower.offset_left = 0; new_flower.offset_top = 0; new_flower.offset_right = 0; new_flower.offset_bottom = 0
			new_flower.configure_flower(chosen_element)
			
			planting_seed = false
			if is_first_free_vase: is_first_free_vase = false 
			highlight_empty_slots(); update_ui(); update_all_flowers_visuals()
				
	elif using_shovel:
		print("Você precisa clicar em cima de uma flower para removê-la!")
		highlight_empty_slots(); update_ui()

func highlight_empty_slots():
	if not grid: return
	for slot in grid.get_children():
		if slot is BaseButton:
			var has_vase = slot.get_meta("has_vase")
			var has_flower = slot.get_child_count() > 1 
			var vase_bg = slot.get_node("VaseBG")
			var style = StyleBoxFlat.new()
			var hover_style = StyleBoxFlat.new()
			
			if has_flower:
				vase_bg.texture = vase_texture; style.bg_color = Color(0, 0, 0, 0.1); slot.disabled = true
			elif has_vase:
				vase_bg.texture = vase_texture
				if planting_seed:
					style.bg_color = Color(0.0, 0.8, 0.0, 0.3) 
					hover_style.bg_color = Color(0.0, 1.0, 0.0, 0.5)
					slot.disabled = false
				else:
					style.bg_color = Color(0, 0, 0, 0.1); slot.disabled = true
			else:
				vase_bg.texture = null
				if positioning_new_vase:
					style.bg_color = Color(0.2, 0.6, 1.0, 0.3)
					hover_style.bg_color = Color(0.2, 0.8, 1.0, 0.5)
					slot.disabled = false
				else:
					style.bg_color = Color(0, 0, 0, 0.1); slot.disabled = true
			
			slot.add_theme_stylebox_override("normal", style)
			slot.add_theme_stylebox_override("hover", hover_style)
			slot.add_theme_stylebox_override("pressed", hover_style)
			slot.add_theme_stylebox_override("disabled", style)
			vase_bg.self_modulate = Color.WHITE; slot.self_modulate = Color.WHITE

func show_flower_tooltip(flower: Button):
	hovered_flower = flower
	if hover_panel: hover_panel.show()
	update_tooltip_text()

func hide_flower_tooltip():
	hovered_flower = null
	if hover_panel: hover_panel.hide()

func update_tooltip_text():
	if not hovered_flower or not hover_label: return
	var stats = hovered_flower.get_current_stats()
	var final_time = stats["time"]
	var base_time = hovered_flower.base_growing_speed
	var base_val = hovered_flower.base_sell_value + sell_value
	var final_val = stats["value"]
	var final_quality = stats["quality"]
	
	var format_stat = func(base, final, sufix, is_inverted=false):
		if final > base + 0.01: 
			var color = "#008000" if not is_inverted else "#ff0000" 
			return str(round(base)) + sufix + " -> [color=" + color + "]" + str(round(final)) + sufix + "[/color]"
		elif final < base - 0.01: 
			var color = "#ff0000" if not is_inverted else "#008000" 
			return str(round(base)) + sufix + " -> [color=" + color + "]" + str(round(final)) + sufix + "[/color]"
		else: return str(round(base)) + sufix
			
	var text = "[center][b]Flower Status[/b][/center]\n\n"
	text += "Growing Time: " + format_stat.call(ceil(base_time), ceil(final_time), "s", true) + "\n"
	text += "Sell Value: " + format_stat.call(base_val, final_val, " Gold") + "\n"
	text += "Harvest Quality: " + format_stat.call(hovered_flower.base_quality_chance, final_quality, "%")
	
	hover_label.text = text
	if hover_panel: hover_panel.size = Vector2.ZERO

func cancel_actions():
	if is_first_free_vase: return 
	if positioning_new_vase:
		positioning_new_vase = false; player_gold += calculating_upgrade_cost(1000, 1.75, vase_level - 1)
		vase_level -= 1; highlight_empty_slots(); update_ui()
	elif planting_seed:
		planting_seed = false; player_gold += calculating_upgrade_cost(100, 1.10, seed_buy_count - 1) 
		seed_buy_count -= 1; highlight_empty_slots(); update_ui()
	elif using_shovel:
		using_shovel = false; highlight_empty_slots(); update_ui()

func _input(event):
	if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed):
		cancel_actions()

func get_prestige_target() -> int:
	if prestige_count == 0: return 100000 
	elif prestige_count == 1: return 1000000 
	else: return roundi(1000000 * pow(1.5, prestige_count - 1))

func do_prestige():
	if total_accumulated_gold >= get_prestige_target():
		magic_scrolls += floor (sqrt (int(total_accumulated_gold / get_prestige_target())))*5
		prestige_count += 1; global_gold_multiplier = 1.0 + (prestige_count * 0.05) 
		current_season = ((current_season + 1) % 4) as Season
		player_gold = 0; total_accumulated_gold = 0 
		growing_speed_level = 0
		irrigation_bonus_level = 0; irrigation_bonus = 1.0
		sell_value_level = 0; sell_value = 0 
		vase_level = 0; seed_buy_count = 0 
		for element in gold_yield.keys(): gold_yield[element] = 0
		
		for f in fusion_times.keys(): fusion_times[f] = 0
		
		update_yield_ui(); build_grid()
		is_first_free_vase = true; positioning_new_vase = true ; planting_seed = false
		highlight_empty_slots(); update_ui()

func add_gold(quantity):
	player_gold += quantity; total_accumulated_gold += quantity ; update_ui()

func _on_prestige_button_pressed() -> void: do_prestige()
func _on_skill_tree_button_pressed() -> void: if skill_tree_menu: skill_tree_menu.update_tree_visuals(); skill_tree_menu.show()
func _on_encyclopedia_button_pressed() -> void: if encyclopedia_menu: encyclopedia_menu.open_encyclopedia()

func _on_fire_button_pressed() -> void: chosen_element = Element.Fire; if plant_seed_button: plant_seed_button.modulate = Color("#ff0000")
func _on_earth_button_pressed() -> void: chosen_element = Element.Earth; if plant_seed_button: plant_seed_button.modulate = Color("#6aa84f")
func _on_water_button_pressed() -> void: chosen_element = Element.Water; if plant_seed_button: plant_seed_button.modulate = Color("4a86e8")
func _on_air_button_pressed() -> void: chosen_element = Element.Air; if plant_seed_button: plant_seed_button.modulate = Color("#ff9900")
	
func record_gold_yield(element: Element, amount: int):
	gold_yield[element] += amount; update_yield_ui()

func update_yield_ui():
	if not yield_container: return
	for child in yield_container.get_children(): child.queue_free()
		
	var max_gold = 0
	for element in gold_yield:
		if gold_yield[element] > max_gold: max_gold = gold_yield[element]
			
	if max_gold == 0: return 
	
	var title = Label.new()
	title.text = "Yielding Chart"; title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	yield_container.add_child(title)
	
	var sorted_elements = gold_yield.keys()
	sorted_elements.sort_custom(func(a, b): return gold_yield[a] > gold_yield[b])
	
	for element in sorted_elements:
		var amount = gold_yield[element]
		if amount > 0:
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.text = str(Element.keys()[element]) + ": " + str(amount)
			label.custom_minimum_size = Vector2(50, 0) # Diminuímos a largura do nome do elemento
			
			var progress = ProgressBar.new()
			progress.max_value = max_gold; progress.value = amount
			progress.custom_minimum_size = Vector2(100, 15); progress.show_percentage = false # Deixamos a barra mais curta e mais fina!
			
			var style = StyleBoxFlat.new()
			match element:
				Element.Fire: style.bg_color = Color("#ff0000")
				Element.Earth: style.bg_color = Color("#6aa84f")
				Element.Water: style.bg_color = Color("#4a86e8")
				Element.Air: style.bg_color = Color("#ff9900")
			progress.add_theme_stylebox_override("fill", style)
			
			hbox.add_child(label); hbox.add_child(progress); yield_container.add_child(hbox)

func update_all_flowers_visuals():
	if not grid: return
	for slot in grid.get_children():
		if slot.get_child_count() > 1: 
			var flower = slot.get_child(1) 
			if flower.has_method("update_buff_visuals"): flower.update_buff_visuals()

func _scan_for_fusions():
	var active_fusions_this_tick = {}
	if not grid: return
	for slot in grid.get_children():
		if slot.get_child_count() > 1:
			var flower = slot.get_child(1)
			var adjacents = flower.get_affecting_flowers()
			
			for adj_data in adjacents:
				if adj_data["distance"] == 1:
					var neighbor = adj_data["flower"]
					var pair = [flower.current_type, neighbor.current_type]
					
					if unlocked_alchemy_lava and not discovered_fusions[Element.Lava] and pair.has(Element.Fire) and pair.has(Element.Earth):
						active_fusions_this_tick[Element.Lava] = [flower, neighbor]
					elif unlocked_alchemy_vapor and not discovered_fusions[Element.Vapor] and pair.has(Element.Fire) and pair.has(Element.Water):
						active_fusions_this_tick[Element.Vapor] = [flower, neighbor]
					elif unlocked_alchemy_plasma and not discovered_fusions[Element.Plasma] and pair.has(Element.Fire) and pair.has(Element.Air):
						active_fusions_this_tick[Element.Plasma] = [flower, neighbor]
					elif unlocked_alchemy_mud and not discovered_fusions[Element.Mud] and pair.has(Element.Water) and pair.has(Element.Earth):
						active_fusions_this_tick[Element.Mud] = [flower, neighbor]
					elif unlocked_alchemy_sand and not discovered_fusions[Element.Sand] and pair.has(Element.Air) and pair.has(Element.Earth):
						active_fusions_this_tick[Element.Sand] = [flower, neighbor]
					elif unlocked_alchemy_ice and not discovered_fusions[Element.Ice] and pair.has(Element.Air) and pair.has(Element.Water):
						active_fusions_this_tick[Element.Ice] = [flower, neighbor]

	var all_fusions = [Element.Lava, Element.Vapor, Element.Plasma, Element.Mud, Element.Sand, Element.Ice]
	
	for fusion_type in all_fusions:
		if active_fusions_this_tick.has(fusion_type):
			fusion_times[fusion_type] += 1
			print("Fundindo " + Element.keys()[fusion_type] + "... " + str(fusion_times[fusion_type]) + "/" + str(fusion_requirement))
			
			if fusion_times[fusion_type] >= fusion_requirement:
				var target_flowers = active_fusions_this_tick[fusion_type]
				_trigger_fusion(fusion_type, target_flowers[0], target_flowers[1])
		else:
			if fusion_times[fusion_type] > 0:
				fusion_times[fusion_type] = 0 
				print("Fusão de " + Element.keys()[fusion_type] + " interrompida!")

func _trigger_fusion(fusion_type: Element, flower1: Button, flower2: Button):
	discovered_fusions[fusion_type] = true
	var slot_to_keep = flower1.get_parent()
	var slot_to_empty = flower2.get_parent()
	
	slot_to_keep.remove_child(flower1); flower1.queue_free()
	slot_to_empty.remove_child(flower2); flower2.queue_free()
	
	slot_to_empty.set_meta("has_vase", true) 
	
	var new_flower = vase_scene.instantiate()
	slot_to_keep.add_child(new_flower)
	
	new_flower.clip_text = true 
	new_flower.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART 
	new_flower.custom_minimum_size = Vector2.ZERO 
	new_flower.size = slot_to_keep.size 
	new_flower.set_anchors_preset(Control.PRESET_FULL_RECT)
	new_flower.offset_left = 0; new_flower.offset_top = 0; new_flower.offset_right = 0; new_flower.offset_bottom = 0
	
	new_flower.configure_flower(fusion_type)
	highlight_empty_slots(); update_ui(); call_deferred("update_all_flowers_visuals")
	
	var colors = {
		Element.Lava: "#ff6600", Element.Vapor: "#ead1dc", Element.Plasma: "#8e7cc3",
		Element.Mud: "#38761d", Element.Sand: "#f9cb9c", Element.Ice: "#00ffff"
	}
	
	var notif = Label.new()
	notif.text = Element.keys()[fusion_type].to_upper() + " SEED DISCOVERED!"
	notif.modulate = Color(colors[fusion_type])
	notif.add_theme_constant_override("outline_size", 6)
	notif.add_theme_color_override("font_outline_color", Color.BLACK)
	notif.global_position = slot_to_keep.global_position + Vector2(-50, -30)
	if has_node("CanvasLayer"): get_node("CanvasLayer").add_child(notif)
	
	var tween = create_tween()
	tween.tween_property(notif, "position:y", notif.position.y - 100, 3.0)
	tween.parallel().tween_property(notif, "modulate:a", 0.0, 3.0)
	tween.tween_callback(notif.queue_free)

func activate_ladybug_buff():
	var base_time = 150.0
	var extra_time = lasting_luck_level * 30.0 
	
	if ladybug_buff_time <= 0:
		global_gold_multiplier += 1.0 
		print("Buff da Joaninha Ativado! 2x Ouro!")
		
	ladybug_buff_time += (base_time + extra_time)
	update_ui()

func activate_mana_storm():
	var base_time = 60.0
	var extra_time = blue_clouds_level * 20.0
	
	if mana_storm_time <= 0:
		mana_storm_multiplier = 2.0 + (mana_flood_level * 0.5) 
		print("Tempestade de Mana Ativada! Tudo cresce mais rápido!")
		
	mana_storm_time += (base_time + extra_time)

func _process(delta):
	if Input.is_action_just_pressed("tecla_m"): add_gold(50000)
	if Input.is_action_just_pressed("tecla_p"): add_gold(500000)
		
	if hover_panel and hover_panel.visible:
		var mouse_pos = get_global_mouse_position()
		var panel_size = hover_panel.size
		var screen_size = get_viewport_rect().size
		
		var target_pos = mouse_pos + Vector2(15, 15)
		if target_pos.x + panel_size.x > screen_size.x: target_pos.x = screen_size.x - panel_size.x - 10 
		if target_pos.y + panel_size.y > screen_size.y: target_pos.y = mouse_pos.y - panel_size.y - 15 
			
		hover_panel.global_position = target_pos
		if hovered_flower != null: update_tooltip_text()
		
	if ladybug_buff_time > 0:
		ladybug_buff_time -= delta
		if ladybug_timer_ui:
			ladybug_timer_ui.text = " Golden Ladybug: " + str(ceil(ladybug_buff_time)) + "s"
			ladybug_timer_ui.show()
		if ladybug_buff_time <= 0:
			ladybug_buff_time = 0
			global_gold_multiplier -= 1.0 
			print("Buff da Joaninha Acabou.")
			if ladybug_timer_ui: ladybug_timer_ui.hide()
			update_ui()
			
	if mana_storm_time > 0:
		mana_storm_time -= delta
		if mana_storm_timer_ui:
			mana_storm_timer_ui.text = " Mana Storm: " + str(ceil(mana_storm_time)) + "s"
			mana_storm_timer_ui.show()
		if mana_storm_time <= 0:
			mana_storm_time = 0
			mana_storm_multiplier = 1.0 
			print("Tempestade de Mana Acabou.")
			if mana_storm_timer_ui: mana_storm_timer_ui.hide()
