extends Control
## Raíz del juego: cambia de pantalla con un fundido corto y muestra los avisos de logros.

const SCREENS := {
	"boot": "res://scripts/screens/boot.gd",
	"menu": "res://scripts/screens/menu.gd",
	"profiles": "res://scripts/screens/profiles.gd",
	"achievements": "res://scripts/screens/achievements.gd",
	"briefing": "res://scripts/screens/briefing.gd",
	"hub": "res://scripts/screens/hub.gd",
	"zones": "res://scripts/screens/zones.gd",
	"plan": "res://scripts/screens/plan.gd",
	"design": "res://scripts/screens/design.gd",
	"transit": "res://scripts/screens/transit.gd",
	"ops": "res://scripts/screens/ops.gd",
	"debrief": "res://scripts/screens/debrief.gd",
	"progress": "res://scripts/screens/progress.gd",
	"library": "res://scripts/screens/library.gd"
}

var current: Control
var current_name := ""
var veil: ColorRect
var busy := false
var banner: Control
var banner_id := ""
var banner_age := 0.0
var start_screen := "boot"

func _ready() -> void:
	Game.main = self
	UIK.setup()
	veil = ColorRect.new()
	veil.color = Color(UIK.INK, 0.0)
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.z_index = 100
	add_child(veil)
	banner = Control.new()
	banner.set_anchors_preset(Control.PRESET_FULL_RECT)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.z_index = 90
	banner.draw.connect(draw_banner)
	add_child(banner)
	show_screen(start_screen, true)

func show_screen(screen: String, instant: bool = false) -> void:
	if busy: return   # un cambio a la vez: los clics rápidos no apilan transiciones
	busy = true
	get_tree().paused = false
	if not instant and not Game.reduced_motion:
		var out := create_tween()
		out.tween_property(veil, "color:a", 1.0, 0.2)
		await out.finished
	if is_instance_valid(current): current.queue_free()
	current = Control.new()
	current.set_script(load(SCREENS[screen]))
	current.set_anchors_preset(Control.PRESET_FULL_RECT)
	current.name = screen.capitalize()
	current_name = screen
	add_child(current)
	move_child(banner, -1)
	move_child(veil, -1)
	if not instant and not Game.reduced_motion:
		var back := create_tween()
		back.tween_property(veil, "color:a", 0.0, 0.22)
	else: veil.color.a = 0.0
	busy = false

func _process(delta: float) -> void:
	if banner_id == "" and not Game.unlocked_queue.is_empty():
		banner_id = String(Game.unlocked_queue.pop_front())
		banner_age = 0.0
	if banner_id != "":
		banner_age += delta
		if banner_age > 4.0: banner_id = ""
		banner.queue_redraw()

func draw_banner() -> void:
	if banner_id == "": return
	var info: Dictionary = Data.ACHIEVEMENTS[banner_id]
	var slide := clampf(minf(banner_age * 4.0, (4.0 - banner_age) * 4.0), 0.0, 1.0)
	var box := Rect2(size.x * 0.5 - 130, -70 + 86 * slide, 390, 64)   # a la derecha del centro: no tapa los títulos de pantalla
	banner.draw_style_box(UIK.box(UIK.NAVY, 18, UIK.ORANGE, 3, 6), box)
	banner.draw_circle(box.position + Vector2(34, 32), 22, UIK.ORANGE)
	Art.icon(banner, "trophy", box.position + Vector2(34, 32), 30, UIK.INK)
	banner.draw_string(UIK.bold_font, box.position + Vector2(68, 26), Game.t("ACHIEVEMENT UNLOCKED", "LOGRO DESBLOQUEADO"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.MINT)
	banner.draw_string(UIK.title_font, box.position + Vector2(68, 50), Game.tt(info.name), HORIZONTAL_ALIGNMENT_LEFT, 308, 22, UIK.PAPER)
