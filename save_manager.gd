extends Node
const SAVE_PATH = "user://savegame.bin"

func save_game(game_ref):
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	var grid_data = []
	for slot in game_ref.grid.get_children():
		var slot_info = {
			"has_vase": slot.get_meta("has_vase"),
			"flower_element": -1,
			"flower_progress": 0.0
		}
		# Se tiver uma flor (mais de 1 filho, pois o primeiro é o VaseBG)
		if slot.get_child_count() > 1:
			var flower = slot.get_child(1)
			slot_info["flower_element"] = flower.current_type
			slot_info["flower_progress"] = flower.flower_progress
		
		grid_data.append(slot_info)

	var data = {
		"gold": game_ref.player_gold,
		"prestige": game_ref.prestige_count,
		"speed_lvl": game_ref.growing_speed_level,
		"unlocked_fusions": game_ref.discovered_fusions,
		"irrigation_lvl": game_ref.irrigation_bonus_level,
		"irrigation_secs": game_ref.irrigation_seconds,
		"vase_lvl": game_ref.vase_level,
		"seed_count": game_ref.seed_buy_count,
		"first_vase": game_ref.is_first_free_vase,
		"grid_data": grid_data
	}
	file.store_var(data)
	file.close()

func load_game(game_ref):
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var()
	file.close()
	
	game_ref.player_gold = data["gold"]
	game_ref.prestige_count = data["prestige"]
	game_ref.growing_speed_level = data["speed_lvl"]
	game_ref.discovered_fusions = data["unlocked_fusions"]
	game_ref.irrigation_bonus_level = data["irrigation_lvl"]
	game_ref.irrigation_seconds = data["irrigation_secs"]
	game_ref.vase_level = data.get("vase_lvl", 0)
	game_ref.seed_buy_count = data.get("seed_count", 0)
	game_ref.is_first_free_vase = data.get("first_vase", false)

	game_ref.build_grid()
	var grid_info = data.get("grid_data", [])
	
	for i in range(grid_info.size()):
		if i < game_ref.grid.get_child_count():
			var slot = game_ref.grid.get_child(i)
			var info = grid_info[i]
			slot.set_meta("has_vase", info["has_vase"])
			
			# Se havia uma planta salva, recria ela
			if info["flower_element"] != -1:
				var new_flower = game_ref.vase_scene.instantiate()
				slot.add_child(new_flower)
				new_flower.configure_flower(info["flower_element"])
				new_flower.flower_progress = info["flower_progress"]
				new_flower.set_anchors_preset(Control.PRESET_FULL_RECT)
	
	game_ref.update_all_flowers_visuals()
