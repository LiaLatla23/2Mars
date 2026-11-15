extends Control
## Raíz del juego: cambia de pantalla con un fundido corto.

const SCREENS := {
	"menu": "res://scripts/screens/menu.gd",
	"zones": "res://scripts/screens/zones.gd",
	"design": "res://scripts/screens/design.gd",
	"ops": "res://scripts/screens/ops.gd",
	"debrief": "res://scripts/screens/debrief.gd",
	"library": "res://scripts/screens/library.gd"
}

var current: Control
var current_name := ""
var veil: ColorRect
var busy := false

func _ready() -> void:
	Game.main = self
	UIK.setup()
	veil = ColorRect.new()
	veil.color = Color(UIK.NAVY, 0.0)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 100
	add_child(veil)
	show_screen("menu", true)

func show_screen(screen: String, instant: bool = false) -> void:
	if busy: return
	busy = true
	get_tree().paused = false
	if not instant:
		var out := create_tween()
		out.tween_property(veil, "color:a", 1.0, 0.22)
		await out.finished
	if is_instance_valid(current): current.queue_free()
	current = Control.new()
	current.set_script(load(SCREENS[screen]))
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	current.name = screen.capitalize()
	current_name = screen
	add_child(current)
	move_child(veil, -1)
	if not instant:
		var back := create_tween()
		back.tween_property(veil, "color:a", 0.0, 0.25)
	busy = false
