extends Control

@onready var magic_scrolls = $MagicScrolls

# ==========================================
# DICIONÁRIO DE DESCRIÇÕES (TOOLTIPS)
# ==========================================
const SKILL_DESCRIPTIONS = {
	# --- Zoologia ---
	"BuyFireAnimal": "Unlocks the Salamander.\n[color=#ff0000]Fire[/color] flowers gain [color=#008000]+50%[/color] Growing Speed and Sell Value.",
	"BuyEarthAnimal": "Unlocks the Armadillo.\n[color=#6aa84f]Earth[/color] flowers gain [color=#008000]+50%[/color] Growing Speed and Sell Value.",
	"BuyWaterAnimal": "Unlocks the Ray.\n[color=#4a86e8]Water[/color] flowers gain [color=#008000]+50%[/color] Growing Speed and Sell Value.",
	"BuyAirAnimal": "Unlocks the Parakeet.\n[color=#ffcc00]Air[/color] flowers gain [color=#008000]+50%[/color] Growing Speed and Sell Value.",

	"BuyFireCollector": "Automatically collects [color=#ff0000]Fire[/color] Essences when a flower is fully grown.",
	"BuyEarthCollector": "Automatically collects [color=#6aa84f]Earth[/color] Essences when a flower is fully grown.",
	"BuyWaterCollector": "Automatically collects [color=#4a86e8]Water[/color] Essences when a flower is fully grown.",
	"BuyAirCollector": "Automatically collects [color=#ffcc00]Air[/color] Essences when a flower is fully grown.",

	"BuyFireSpecialistCollector": "Automatically collects Fusion Essences containing [color=#ff0000]Fire[/color].",
	"BuyEarthSpecialistCollector": "Automatically collects Fusion Essences containing [color=#6aa84f]Earth[/color].",
	"BuyWaterSpecialistCollector": "Automatically collects Fusion Essences containing [color=#4a86e8]Water[/color].",
	"BuyAirSpecialistCollector": "Automatically collects Fusion Essences containing [color=#ffcc00]Air[/color].",

	# --- Alquimia ---
	"ReleaseLavaSeed": "Unlocks the [color=#ff6600]Lava Flower[/color].\nRequires keeping Fire and Earth adjacent for 30 minutes.",
	"ReleaseVaporSeed": "Unlocks the [color=#ead1dc]Vapor Flower[/color].\nRequires keeping Fire and Water adjacent for 30 minutes.",
	"ReleasePlasmaSeed": "Unlocks the [color=#8e7cc3]Plasma Flower[/color].\nRequires keeping Fire and Air adjacent for 30 minutes.",
	"ReleaseMudSeed": "Unlocks the [color=#38761d]Mud Flower[/color].\nRequires keeping Water and Earth adjacent for 30 minutes.",
	"ReleaseSandSeed": "Unlocks the [color=#f9cb9c]Sand Flower[/color].\nRequires keeping Air and Earth adjacent for 30 minutes.",
	"ReleaseIceSeed": "Unlocks the [color=#00ffff]Ice Flower[/color].\nRequires keeping Air and Water adjacent for 30 minutes.",

	"BuyLavaProducer": "Improves Growing Speed and Sell Value of [color=#ff6600]Lava[/color] flowers by [color=#008000]+10% per level[/color].",
	"BuyVaporProducer": "Improves Growing Speed and Sell Value of [color=#ead1dc]Vapor[/color] flowers by [color=#008000]+10% per level[/color].",
	"BuyPlasmaProducer": "Improves Growing Speed and Sell Value of [color=#8e7cc3]Plasma[/color] flowers by [color=#008000]+10% per level[/color].",
	"BuyMudProducer": "Improves Growing Speed and Sell Value of [color=#38761d]Mud[/color] flowers by [color=#008000]+10% per level[/color].",
	"BuySandProducer": "Improves Growing Speed and Sell Value of [color=#f9cb9c]Sand[/color] flowers by [color=#008000]+10% per level[/color].",
	"BuyIceProducer": "Improves Growing Speed and Sell Value of [color=#00ffff]Ice[/color] flowers by [color=#008000]+10% per level[/color].",

	"BuyPureExtraction": "Harvesting Fusion flowers has a chance to drop [color=#ffcc00]Magic Scrolls[/color]. Chance increases per level.",

	# --- Eventos Naturais ---
	"BuyGoldenLadybug": "Unlocks the [color=#ffcc00]Golden Ladybug[/color] event.\nClick it to [color=#008000]double[/color] the Sell Value of all flowers for 150s.",
	"BuyManaStorm": "Unlocks the [color=#4a86e8]Mana Storm[/color] event.\nClick a charged cloud to [color=#008000]double[/color] Growing Speed for 150s.",
	"BuyAntiPlagueMagic": "Reduces the duration of [color=#800080]Pest Infestations[/color] that cut your Sell Value.",

	"BuyLastingLuck": "Increases the duration of the [color=#ffcc00]Golden Ladybug[/color] buff.",
	"BuyProtectionMagic": "Reduces the base chance (50%) of a [color=#800080]Pest Infestation[/color] starting.",
	"BuyManaFlood": "Increases the duration of the [color=#4a86e8]Mana Storm[/color] buff.",

	"BuyBlueClouds": "Increases the chance of Mana Clouds appearing.",
	"BuyLadybugInfestation": "Increases the base chance (10%) of a Golden Ladybug appearing."
}

func _ready():
	update_tree_visuals()
	_connect_all_tooltips(self) # Chama a varredura logo ao carregar a tela!

func _on_back_to_garden_pressed() -> void:
	hide() 

# ==========================================
# LÓGICA AUTOMÁTICA DO TOOLTIP DE HOVER
# ==========================================

# Varre todos os nós filhos procurando botões mapeados
func _connect_all_tooltips(node: Node):
	for child in node.get_children():
		if child is Button and SKILL_DESCRIPTIONS.has(child.name):
			child.mouse_entered.connect(_on_skill_hovered.bind(child.name))
			child.mouse_exited.connect(_on_skill_unhovered)
		_connect_all_tooltips(child) # Procura dentro dos filhos dos filhos

func _on_skill_hovered(btn_name: String):
	var game = get_node("/root/Game")
	if game.hover_panel:
		game.hovered_flower = null # Evita conflitar com as plantas do jardim
		game.hover_label.text = "[center][b]Skill Info[/b][/center]\n\n" + SKILL_DESCRIPTIONS[btn_name]
		game.hover_panel.show()
		game.hover_panel.size = Vector2.ZERO # Força o Godot a recalcular o tamanho da caixa

func _on_skill_unhovered():
	var game = get_node("/root/Game")
	if game.hover_panel:
		game.hover_panel.hide()


# ==========================================
# O RESTO DO CÓDIGO (COMPRA E ATUALIZAÇÃO)
# ==========================================

func try_buy_upgrade(current_level: int, max_level: int, cost: int) -> bool:
	var game = get_node("/root/Game")
	if current_level < max_level and game.magic_scrolls >= cost:
		game.magic_scrolls -= cost
		return true
	elif current_level >= max_level:
		print("Nível Máximo Atingido!")
		return false
	else:
		print("Pergaminhos Insuficientes! Custa: " + str(cost))
		return false

func set_unlock_btn(btn: Node, title: String, is_unlocked: bool, cost: int):
	if not btn: return 
	if is_unlocked:
		btn.disabled = true; btn.text = title + "\n[UNLOCKED]"
	else:
		btn.disabled = false; btn.text = title + "\nCost: %d Scrolls" % cost

func set_max_level_btn(btn: Node, title: String, level: int, max_lvl: int, cost: int, is_locked: bool, locked_msg: String):
	if not btn: return 
	if is_locked:
		btn.disabled = true; btn.text = title + "\n(" + locked_msg + ")"
	elif level >= max_lvl:
		btn.disabled = true; btn.text = title + "\n[MAX LEVEL]"
	else:
		btn.disabled = false; btn.text = title + "\nLvl: %d/%d\nCost: %d Scrolls" % [level, max_lvl, cost]


func update_tree_visuals():
	var game = get_node("/root/Game")
	if magic_scrolls: magic_scrolls.text = "Magic Scrolls: " + str(game.magic_scrolls)
	
	# --- ATUALIZAÇÃO DO ESPAÇAMENTO DA NOVA UI ---
	var main_columns = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer
	if main_columns:
		for col in main_columns.get_children():
			if col is VBoxContainer:
				col.alignment = BoxContainer.ALIGNMENT_BEGIN 
				col.add_theme_constant_override("separation", 40) 
				
				for row in col.get_children():
					if row is HBoxContainer:
						row.alignment = BoxContainer.ALIGNMENT_CENTER
						row.add_theme_constant_override("separation",40) 
	
	# --- PUXANDO AS GAVETAS DOS NOVOS CAMINHOS ---
	var zoo1 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/ZoologyColumn/ZoologyRow1
	var zoo2 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/ZoologyColumn/ZoologyRow2
	var zoo3 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/ZoologyColumn/ZoologyRow3
	
	var alc1 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/AlchemyColumn/AlchemyRow1
	var alc2 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/AlchemyColumn/AlchemyRow2
	var alc3 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/AlchemyColumn/AlchemyRow3
	
	var evt1 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/EventColumn/EventsRow1
	var evt2 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/EventColumn/EventsRow2
	var evt3 = $MarginContainer/ScrollContainer/MarginContainerInterno/ColumnsContainer/EventColumn/EventsRow3

	# --- ZOOLOGIA ---
	if zoo1 and zoo2 and zoo3:
		set_unlock_btn(zoo1.get_node_or_null("BuyFireAnimal"), "Salamander", game.unlocked_salamander, 2)
		set_unlock_btn(zoo1.get_node_or_null("BuyEarthAnimal"), "Armadillo", game.unlocked_armadillo, 2)
		set_unlock_btn(zoo1.get_node_or_null("BuyWaterAnimal"), "Ray", game.unlocked_ray, 2)
		set_unlock_btn(zoo1.get_node_or_null("BuyAirAnimal"), "Parakeet", game.unlocked_parakeet, 2)

		set_max_level_btn(zoo2.get_node_or_null("BuyFireCollector"), "Fire Collect", game.fire_collecting_level, 1, 3, not game.unlocked_salamander, "Req. Salamander")
		set_max_level_btn(zoo2.get_node_or_null("BuyEarthCollector"), "Earth Collect", game.earth_collecting_level, 1, 3, not game.unlocked_armadillo, "Req. Armadillo")
		set_max_level_btn(zoo2.get_node_or_null("BuyWaterCollector"), "Water Collect", game.water_collecting_level, 1, 3, not game.unlocked_ray, "Req. Ray")
		set_max_level_btn(zoo2.get_node_or_null("BuyAirCollector"), "Air Collect", game.air_collecting_level, 1, 3, not game.unlocked_parakeet, "Req. Parakeet")

		set_max_level_btn(zoo3.get_node_or_null("BuyFireSpecialistCollector"), "Fire Specialist", game.fire_specialist_level, 1, 5, game.fire_collecting_level < 1, "Req. Collection")
		set_max_level_btn(zoo3.get_node_or_null("BuyEarthSpecialistCollector"), "Earth Specialist", game.earth_specialist_level, 1, 5, game.earth_collecting_level < 1, "Req. Collection")
		set_max_level_btn(zoo3.get_node_or_null("BuyWaterSpecialistCollector"), "Water Specialist", game.water_specialist_level, 1, 5, game.water_collecting_level < 1, "Req. Collection")
		set_max_level_btn(zoo3.get_node_or_null("BuyAirSpecialistCollector"), "Air Specialist", game.air_specialist_level, 1, 5, game.air_collecting_level < 1, "Req. Collection")

	# --- ALQUIMIA ---
	if alc1 and alc2 and alc3:
		set_unlock_btn(alc1.get_node_or_null("ReleaseLavaSeed"), "Lava Seed", game.unlocked_alchemy_lava, 5)
		set_unlock_btn(alc1.get_node_or_null("ReleaseVaporSeed"), "Vapor Seed", game.unlocked_alchemy_vapor, 5)
		set_unlock_btn(alc1.get_node_or_null("ReleasePlasmaSeed"), "Plasma Seed", game.unlocked_alchemy_plasma, 5)
		set_unlock_btn(alc1.get_node_or_null("ReleaseMudSeed"), "Mud Seed", game.unlocked_alchemy_mud, 5)
		set_unlock_btn(alc1.get_node_or_null("ReleaseSandSeed"), "Sand Seed", game.unlocked_alchemy_sand, 5)
		set_unlock_btn(alc1.get_node_or_null("ReleaseIceSeed"), "Ice Seed", game.unlocked_alchemy_ice, 5)

		var get_alc_cost = func(lvl): return 1 if lvl < 2 else (3 if lvl < 4 else 5)
		set_max_level_btn(alc2.get_node_or_null("BuyLavaProducer"), "Lava Producer", game.lava_producer_level, 5, get_alc_cost.call(game.lava_producer_level), not game.unlocked_alchemy_lava, "Req. Seed")
		set_max_level_btn(alc2.get_node_or_null("BuyVaporProducer"), "Vapor Producer", game.vapor_producer_level, 5, get_alc_cost.call(game.vapor_producer_level), not game.unlocked_alchemy_vapor, "Req. Seed")
		set_max_level_btn(alc2.get_node_or_null("BuyPlasmaProducer"), "Plasma Producer", game.plasma_producer_level, 5, get_alc_cost.call(game.plasma_producer_level), not game.unlocked_alchemy_plasma, "Req. Seed")
		set_max_level_btn(alc2.get_node_or_null("BuyMudProducer"), "Mud Producer", game.mud_producer_level, 5, get_alc_cost.call(game.mud_producer_level), not game.unlocked_alchemy_mud, "Req. Seed")
		set_max_level_btn(alc2.get_node_or_null("BuySandProducer"), "Sand Producer", game.sand_producer_level, 5, get_alc_cost.call(game.sand_producer_level), not game.unlocked_alchemy_sand, "Req. Seed")
		set_max_level_btn(alc2.get_node_or_null("BuyIceProducer"), "Ice Producer", game.ice_producer_level, 5, get_alc_cost.call(game.ice_producer_level), not game.unlocked_alchemy_ice, "Req. Seed")

		set_max_level_btn(alc3.get_node_or_null("BuyPureExtraction"), "Pure Extraction", game.pure_extraction_level, 5, get_alc_cost.call(game.pure_extraction_level), false, "")

	# --- EVENTOS NATURAIS ---
	if evt1 and evt2 and evt3:
		set_unlock_btn(evt1.get_node_or_null("BuyGoldenLadybug"), "Golden Ladybug", game.unlocked_golden_ladybug, 1)
		set_unlock_btn(evt1.get_node_or_null("BuyManaStorm"), "Mana Storm", game.unlocked_mana_storm, 1)
		# AQUI FOI CORRIGIDO: anti_plague_magic_level
		set_max_level_btn(evt1.get_node_or_null("BuyAntiPlagueMagic"), "Anti-Pest", game.anti_plague_magic_level, 5, game.anti_plague_magic_level + 1, false, "")

		set_max_level_btn(evt2.get_node_or_null("BuyLastingLuck"), "Lasting Luck", game.lasting_luck_level, 5, game.lasting_luck_level + 1, not game.unlocked_golden_ladybug, "Req. Ladybug")
		set_max_level_btn(evt2.get_node_or_null("BuyProtectionMagic"), "Protection Magic", game.protection_magic_level, 5, game.protection_magic_level + 1, false, "")
		set_max_level_btn(evt2.get_node_or_null("BuyManaFlood"), "Mana Flood", game.mana_flood_level, 5, game.mana_flood_level + 1, not game.unlocked_mana_storm, "Req. Storm")

		set_max_level_btn(evt3.get_node_or_null("BuyLadybugInfestation"), "Infestation", game.ladybug_infestation_level, 5, game.ladybug_infestation_level + 1, not game.unlocked_golden_ladybug, "Req. Ladybug")
		set_max_level_btn(evt3.get_node_or_null("BuyBlueClouds"), "Blue Clouds", game.blue_clouds_level, 5, game.blue_clouds_level + 1, not game.unlocked_mana_storm, "Req. Storm")

# ==========================================
# FUNÇÕES DE CLIQUE (ZOOLOGIA)
# ==========================================
func _on_buy_fire_animal_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 2) and not g.unlocked_salamander: g.unlocked_salamander = true; g.update_ui(); update_tree_visuals()
func _on_buy_earth_animal_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 2) and not g.unlocked_armadillo: g.unlocked_armadillo = true; g.update_ui(); update_tree_visuals()
func _on_buy_water_animal_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 2) and not g.unlocked_ray: g.unlocked_ray = true; g.update_ui(); update_tree_visuals()
func _on_buy_air_animal_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 2) and not g.unlocked_parakeet: g.unlocked_parakeet = true; g.update_ui(); update_tree_visuals()

func _on_buy_fire_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.fire_collecting_level, 1, 3): g.fire_collecting_level += 1; g.update_ui(); update_tree_visuals()
func _on_buy_earth_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.earth_collecting_level, 1, 3): g.earth_collecting_level += 1; g.update_ui(); update_tree_visuals()
func _on_buy_water_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.water_collecting_level, 1, 3): g.water_collecting_level += 1; g.update_ui(); update_tree_visuals()
func _on_buy_air_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.air_collecting_level, 1, 3): g.air_collecting_level += 1; g.update_ui(); update_tree_visuals()

func _on_buy_fire_specialist_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.fire_specialist_level, 1, 5): g.fire_specialist_level += 1; update_tree_visuals()
func _on_buy_earth_specialist_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.earth_specialist_level, 1, 5): g.earth_specialist_level += 1; update_tree_visuals()
func _on_buy_water_specialist_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.water_specialist_level, 1, 5): g.water_specialist_level += 1; update_tree_visuals()
func _on_buy_air_specialist_collector_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.air_specialist_level, 1, 5): g.air_specialist_level += 1; update_tree_visuals()

# ==========================================
# FUNÇÕES DE CLIQUE (ALQUIMIA)
# ==========================================
func _on_release_lava_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_lava: g.unlocked_alchemy_lava = true; update_tree_visuals()
func _on_release_vapor_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_vapor: g.unlocked_alchemy_vapor = true; update_tree_visuals()
func _on_release_plasma_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_plasma: g.unlocked_alchemy_plasma = true; update_tree_visuals()
func _on_release_mud_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_mud: g.unlocked_alchemy_mud = true; update_tree_visuals()
func _on_release_sand_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_sand: g.unlocked_alchemy_sand = true; update_tree_visuals()
func _on_release_ice_seed_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 5) and not g.unlocked_alchemy_ice: g.unlocked_alchemy_ice = true; update_tree_visuals()

func _on_buy_lava_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.lava_producer_level < 2 else (3 if g.lava_producer_level < 4 else 5); if try_buy_upgrade(g.lava_producer_level, 5, c): g.lava_producer_level += 1; update_tree_visuals()
func _on_buy_vapor_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.vapor_producer_level < 2 else (3 if g.vapor_producer_level < 4 else 5); if try_buy_upgrade(g.vapor_producer_level, 5, c): g.vapor_producer_level += 1; update_tree_visuals()
func _on_buy_plasma_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.plasma_producer_level < 2 else (3 if g.plasma_producer_level < 4 else 5); if try_buy_upgrade(g.plasma_producer_level, 5, c): g.plasma_producer_level += 1; update_tree_visuals()
func _on_buy_mud_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.mud_producer_level < 2 else (3 if g.mud_producer_level < 4 else 5); if try_buy_upgrade(g.mud_producer_level, 5, c): g.mud_producer_level += 1; update_tree_visuals()
func _on_buy_sand_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.sand_producer_level < 2 else (3 if g.sand_producer_level < 4 else 5); if try_buy_upgrade(g.sand_producer_level, 5, c): g.sand_producer_level += 1; update_tree_visuals()
func _on_buy_ice_producer_pressed(): var g = get_node("/root/Game"); var c = 1 if g.ice_producer_level < 2 else (3 if g.ice_producer_level < 4 else 5); if try_buy_upgrade(g.ice_producer_level, 5, c): g.ice_producer_level += 1; update_tree_visuals()

func _on_buy_pure_extraction_pressed(): var g = get_node("/root/Game"); var c = 1 if g.pure_extraction_level < 2 else (3 if g.pure_extraction_level < 4 else 5); if try_buy_upgrade(g.pure_extraction_level, 5, c): g.pure_extraction_level += 1; update_tree_visuals()

# ==========================================
# FUNÇÕES DE CLIQUE (EVENTOS NATURAIS)
# ==========================================
func _on_buy_anti_plague_magic_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.anti_plague_magic_level, 5, g.anti_plague_magic_level + 1): g.anti_plague_magic_level += 1; update_tree_visuals()
func _on_buy_protection_magic_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.protection_magic_level, 5, g.protection_magic_level + 1): g.protection_magic_level += 1; update_tree_visuals()

func _on_buy_mana_storm_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 1) and not g.unlocked_mana_storm: g.unlocked_mana_storm = true; update_tree_visuals()
func _on_buy_mana_flood_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.mana_flood_level, 5, g.mana_flood_level + 1): g.mana_flood_level += 1; update_tree_visuals()
func _on_buy_blue_clouds_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.blue_clouds_level, 5, g.blue_clouds_level + 1): g.blue_clouds_level += 1; update_tree_visuals()

func _on_buy_golden_ladybug_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(0, 1, 1) and not g.unlocked_golden_ladybug: g.unlocked_golden_ladybug = true; update_tree_visuals()
func _on_buy_lasting_luck_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.lasting_luck_level, 5, g.lasting_luck_level + 1): g.lasting_luck_level += 1; update_tree_visuals()
func _on_buy_ladybug_infestation_pressed(): var g = get_node("/root/Game"); if try_buy_upgrade(g.ladybug_infestation_level, 5, g.ladybug_infestation_level + 1): g.ladybug_infestation_level += 1; update_tree_visuals()
