extends Node
## Comprobación de compilación: carga todos los scripts con los autoloads activos.
## Uso: godot --headless res://tests/Compile.tscn

func _ready() -> void:
	var bad := 0
	var count := 0
	for dir in ["res://scripts", "res://scripts/screens", "res://tests"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"): continue
			count += 1
			var script = load(dir + "/" + file)
			if script == null or not (script as GDScript).can_instantiate():
				bad += 1
				print("COMPILE FAIL: ", dir + "/" + file)
	print("COMPILE SUMMARY: %d scripts; %d failures" % [count, bad])
	get_tree().quit(1 if bad > 0 else 0)
