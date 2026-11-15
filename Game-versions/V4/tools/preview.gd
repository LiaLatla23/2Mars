extends Control
## Herramienta de desarrollo: renderiza escenarios 3D a PNG para revisarlos.
##   godot --path . res://tools/Preview.tscn -- --out=CARPETA [--scene=workshop|vista|mars]
var out := "user://preview"
var kind := "workshop"
var stage: Stage3D
var t := 0
func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--scene="): kind = arg.trim_prefix("--scene=")
	UIK.setup()
	DirAccess.make_dir_recursive_absolute(out)
	stage = Stage3D.make(self, Rect2(0, 0, 1280, 720))
	var b := Data.default_build()
	if kind == "full":
		b = {"chassis": "chassis_reinf", "deck": "deck_ext", "wheels": "wheels_reinf", "power": "rtg", "computer": "cpu_adv", "arm": "arm_ext", "parts": ["uhf", "hga", "battery_ext", "storage", "mastcam", "supercam", "pixl", "sherloc", "drill", "rimfax", "meda", "moxie", "rocker", "navsens", "autonav", "regolith"]}
		stage.workshop()
	elif kind == "vista":
		stage.vista()
		stage.goal = Vector3(0.0, 0.06, 26.0)
		stage.orbit = stage.goal
	else: stage.workshop(kind == "mars")
	if kind != "vista": stage.show_rover(b)
func _process(_d: float) -> void:
	t += 1
	if t == 12:
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, kind])
		get_tree().quit()
