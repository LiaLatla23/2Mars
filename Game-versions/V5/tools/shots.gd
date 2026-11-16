extends Node
## Herramienta de desarrollo: abre una pantalla del juego real y guarda capturas.
##   godot --path . res://tools/Shots.tscn -- --screen=ops --out=CARPETA [--es] [--zone=life]
##     [--full] [--steps=begin,drive:90,shot,call:show_pause,shot] [--name=prefijo]
## Usa el guardado de pruebas (no toca partidas reales).
const FULL := {"chassis": "chassis_reinf", "deck": "deck_ext", "wheels": "wheels_reinf", "power": "rtg", "computer": "cpu_adv", "arm": "arm_ext", "parts": ["uhf", "hga", "battery_ext", "storage", "mastcam", "supercam", "pixl", "sherloc", "drill", "rimfax", "meda", "moxie", "rocker", "navsens", "autonav", "regolith"]}
var main: Control
var out := "user://shots"
var prefix := "shot"
var count := 0
var mouse := Vector2(640, 360)
var held := false

func arg(key: String, fallback: String = "") -> String:
	for item in OS.get_cmdline_user_args():
		if item.begins_with("--%s=" % key): return item.trim_prefix("--%s=" % key)
	return fallback

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func shot() -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s_%02d.png" % [out, prefix, count])
	count += 1

func _ready() -> void:
	out = arg("out", out)
	prefix = arg("name", arg("screen", "shot"))
	DirAccess.make_dir_recursive_absolute(out)
	Game.save_path = "user://2mars_shots_save.json"
	if arg("keep") == "" and FileAccess.file_exists(Game.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.save_path))
	Game.load_save()
	Game.lang = "es" if "--es" in OS.get_cmdline_user_args() else "en"
	Game.setup_done = true
	Game.volume = 0.7 if "--sound" in OS.get_cmdline_user_args() else 0.0
	Game.apply_volume()
	Game.start_slot(0, true)
	Game.player_name = "Ada"
	Game.team_name = "SpaceNuts"
	Game.rover_name = "ARES 01"
	Game.zone = arg("zone", "geology")
	Game.tutorial = {"ops": arg("tutorial") == "", "workshop": arg("tutorial") == "", "intro": true}
	if "--full" in OS.get_cmdline_user_args(): Game.build = FULL.duplicate(true)
	if "--progress" in OS.get_cmdline_user_args():
		Game.progress = {"geology": {"grade": "A", "science": 130, "runs": 2}, "life": {"grade": "B", "science": 96, "runs": 1}}
		for id in ["first_launch", "touchdown", "first_data", "context", "angles", "night"]: Game.achievements[id] = true
		Game.history = [{"zone": "geology", "grade": "B", "science": 80, "issues": ["energy"], "received": 40, "need": 45}, {"zone": "geology", "grade": "A", "science": 130, "issues": [], "received": 52, "need": 45}]
	Game.quality = int(arg("quality", "1"))
	Game.auto_quality = false
	if arg("coop") != "":
		Game.coop = true
		Game.coop_mode = arg("coop")
	if arg("sub") != "": Game.sub = arg("sub")
	main = load("res://scenes/Main.tscn").instantiate()
	main.start_screen = arg("screen", "menu")
	add_child(main)
	await frames(int(arg("wait", "40")))
	for step in arg("steps", "shot").split(",", false):
		var parts := step.split(":")
		match parts[0]:
			"shot": await shot()
			"wait": await frames(int(parts[1]))
			"call":
				if main.current.has_method(parts[1]): main.current.callv(parts[1], Array(parts.slice(2)))
				await frames(6)
			"go":
				main.show_screen(parts[1], true)
				await frames(20)
			"begin":
				main.current.begin()
				await frames(4)
			"press":
				for node in main.current.find_children("*", "Button", true, false):
					if (node as Button).text.contains(parts[1]) and (node as Button).is_visible_in_tree():
						(node as Button).pressed.emit()
						break
				await frames(10)
			"drive":
				Input.action_press(parts[2] if parts.size() > 2 else "move_right")
				await frames(int(parts[1]))
				Input.action_release(parts[2] if parts.size() > 2 else "move_right")
			"move":   # move:x:y[:frames] — lleva el cursor suavemente (dispara hover real)
				var goal := Vector2(float(parts[1]), float(parts[2]))
				var steps := int(parts[3]) if parts.size() > 3 else 14
				var from := mouse
				for i in range(steps):
					var next := from.lerp(goal, smoothstep(0.0, 1.0, float(i + 1) / steps))
					var motion := InputEventMouseMotion.new()
					motion.position = next
					motion.global_position = next
					motion.relative = next - mouse
					motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
					mouse = next
					Input.parse_input_event(motion)
					await frames(1)
			"down", "up", "click":
				for pressed in ([true, false] if parts[0] == "click" else [parts[0] == "down"]):
					var button := InputEventMouseButton.new()
					button.button_index = MOUSE_BUTTON_LEFT
					button.pressed = pressed
					button.position = mouse
					button.global_position = mouse
					held = pressed
					Input.parse_input_event(button)
					await frames(3)
			"perf":   # perf:frames — tiempos de fotograma reales (sin --fixed-fps)
				var times: Array = []
				var last := Time.get_ticks_usec()
				for i in range(int(parts[1])):
					await get_tree().process_frame
					var now := Time.get_ticks_usec()
					times.append((now - last) / 1000.0)
					last = now
				times.sort()
				var total := 0.0
				for value in times: total += float(value)
				print("PERF %s %s: avg %.1f ms · p95 %.1f ms · max %.1f ms · %d frames · adapter %s" % [main.current_name, get_window().size, total / times.size(), times[int(times.size() * 0.95)], times[-1], times.size(), RenderingServer.get_video_adapter_name()])
			"print": print("PRINT ", parts[1], " = ", main.current.get(parts[1]), " | music=", Game.track_id)
			"set":
				main.current.set(parts[1], str_to_var(parts[2]))
				await frames(2)
	get_tree().quit()
