extends Node
## Recorrido de medición (V5). Visita las pantallas principales con una partida de prueba y
## escribe, por pantalla y calidad: tiempo de fotograma (media, p95, máximo), llamadas de
## dibujo, primitivas y memoria. Sirve para comparar antes/después EN EL MISMO EQUIPO.
##   Escritorio:  godot --path . res://tools/PerfTour.tscn [-- --all] [--frames=150]
##   Navegador:   index.html?perf   (o ?perf=all) — el resultado sale en la consola
## No toca la partida real: usa su propio archivo de guardado.

const FULL := {"chassis": "chassis_reinf", "deck": "deck_ext", "wheels": "wheels_reinf", "power": "rtg", "computer": "cpu_adv", "arm": "arm_ext",
	"parts": ["uhf", "hga", "battery_ext", "storage", "mastcam", "supercam", "pixl", "sherloc", "drill", "rimfax", "meda", "moxie", "rocker", "navsens", "autonav", "regolith"]}

var main: Node
var all_levels := false
var count := 150
var started_ms := 0

func _ready() -> void:
	started_ms = Time.get_ticks_msec()
	for item in OS.get_cmdline_user_args():
		if item == "--all": all_levels = true
		if item.begins_with("--frames="): count = int(item.split("=")[1])
	if get_parent() != null and get_parent().has_method("show_screen"): main = get_parent()
	else:
		main = load("res://scenes/Main.tscn").instantiate()
		main.start_screen = "menu"
		add_child(main)
	run.call_deferred()

func frames(n: int) -> void:
	for i in range(n): await get_tree().process_frame

func run() -> void:
	await frames(5)
	Game.save_path = "user://2mars_perf_save.json"
	Game.load_save()
	Game.setup_done = true
	Game.volume = 0.0
	Game.apply_volume()
	Game.start_slot(0, true)
	Game.player_name = "Perf"
	Game.rover_name = "ARES 01"
	Game.zone = "archive"
	Game.tutorial = {"ops": true, "workshop": true, "intro": true}
	Game.build = FULL.duplicate(true)
	Game.plan = Game.default_plan()
	Game.plan.profile = "flagship"
	Game.plan["launcher"] = "heavy"
	Game.progress = {"geology": {"grade": "A", "science": 130, "runs": 2}, "life": {"grade": "B", "science": 96, "runs": 1}}
	if Game.get("auto_quality") != null: Game.set("auto_quality", false)
	print("PERF adapter %s · window %s · started after %d ms" % [RenderingServer.get_video_adapter_name(), get_window().size, started_ms])
	print("PERF|quality|screen|avg ms|p95 ms|max ms|draw calls|primitives|objects|static MB")
	var levels := [0, 1, 2] if all_levels else [Game.quality]
	for level in levels:
		Game.quality = level
		for screen in ["menu", "hub", "design", "zones", "progress", "ops"]:
			var began := Time.get_ticks_msec()
			main.show_screen(screen, true)
			await frames(12)
			if screen == "ops":
				Game.flight = {"charge": 1.0, "damage": 2.0, "near": 0.0, "delay": 0.0}
				main.current.begin()
				Input.action_press("move_right")
			var load_ms := Time.get_ticks_msec() - began
			await frames(30)
			var times: Array = []
			var draws := 0
			var prims := 0
			var objects := 0
			var last := Time.get_ticks_usec()
			for i in range(count):
				await get_tree().process_frame
				var now := Time.get_ticks_usec()
				times.append((now - last) / 1000.0)
				last = now
				draws = maxi(draws, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
				prims = maxi(prims, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
				objects = maxi(objects, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME))
			Input.action_release("move_right")
			times.sort()
			var total := 0.0
			for value in times: total += float(value)
			print("PERF|%s|%s|%.1f|%.1f|%.1f|%d|%d|%d|%.0f|open %d ms" % [["low", "medium", "high"][level], screen, total / times.size(), times[int(times.size() * 0.95)], times[-1], draws, prims, objects, OS.get_static_memory_usage() / 1048576.0, load_ms])
	print("PERF DONE")
	if not OS.has_feature("web"): get_tree().quit()
