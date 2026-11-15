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
	"library": "res://scripts/screens/library.gd",
	"upgrades": "res://scripts/screens/upgrades.gd"
}

var current: Control
var current_name := ""
var veil: ColorRect
var busy := false
var banner: Control
var banner_id := ""
var banner_age := 0.0
var start_screen := "boot"
var meter: Label              # medidor de fotogramas (F3)
var frame_times: Array = []

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
	meter = UIK.label(self, "", 14, UIK.PAPER, "bold")
	meter.position = Vector2(8, 696)
	meter.z_index = 95
	meter.add_theme_color_override("font_outline_color", UIK.INK)
	meter.add_theme_constant_override("outline_size", 5)
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_screen(start_screen, true)

func show_screen(screen: String, instant: bool = false) -> void:
	if busy: return   # un cambio a la vez: los clics rápidos no apilan transiciones
	busy = true
	get_tree().paused = false
	veil.mouse_filter = Control.MOUSE_FILTER_STOP   # durante el cambio no se pulsa nada de la pantalla saliente
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
	# música por contexto: base (menús y taller), tensión (viaje), exploración y resolución
	var theme := "base"
	if screen == "ops": theme = "explore"
	elif screen == "transit": theme = "tension"
	elif screen == "debrief": theme = "resolve" if String(Game.report.get("grade", "D")) in ["S", "A", "B"] else "base"
	Game.play_music(theme)
	add_child(current)
	move_child(banner, -1)
	move_child(veil, -1)
	if not instant and not Game.reduced_motion:
		var back := create_tween()
		back.tween_property(veil, "color:a", 0.0, 0.22)
	else: veil.color.a = 0.0
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	move_child(meter, -1)
	busy = false

func _process(delta: float) -> void:
	if banner_id == "" and not Game.unlocked_queue.is_empty():
		banner_id = String(Game.unlocked_queue.pop_front())
		banner_age = 0.0
		Game.sfx("reward")
	if banner_id != "":
		banner_age += delta
		if banner_age > 3.6: banner_id = ""
		banner.queue_redraw()
	if Game.show_fps:
		frame_times.append(delta)
		if frame_times.size() > 120: frame_times.pop_front()
		var worst := 0.0
		var total := 0.0
		for value in frame_times:
			worst = maxf(worst, float(value))
			total += float(value)
		meter.text = "%d FPS · %.1f ms (max %.1f ms) · %s" % [int(Engine.get_frames_per_second()), 1000.0 * total / frame_times.size(), worst * 1000.0, [Game.t("low", "baja"), Game.t("medium", "media"), Game.t("high", "alta")][Game.quality]]
	meter.visible = Game.show_fps

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F3:
		Game.show_fps = not Game.show_fps
		frame_times = []

## Aviso de logro. Aparece de uno en uno y en la zona que reserva cada pantalla
## (BaseScreen.notice_at), para no tapar títulos, barras ni acciones.
func draw_banner() -> void:
	if banner_id == "": return
	var info: Dictionary = Data.ACHIEVEMENTS[banner_id]
	var slide := clampf(minf(banner_age * 5.0, (3.6 - banner_age) * 5.0), 0.0, 1.0)
	if Game.reduced_motion: slide = 1.0
	var eased := 1.0 - pow(1.0 - slide, 3.0)
	var at: Vector2 = current.get("notice_at") if is_instance_valid(current) and current.get("notice_at") != null else Vector2(445, 6)
	var box := Rect2(at + Vector2(0, -18.0 * (1.0 - eased)), Vector2(390, 62))
	banner.modulate.a = eased
	banner.draw_style_box(UIK.box(UIK.NAVY, 18, UIK.ORANGE, 3, 6), box)
	var medal := UIK.tex(String(Data.ACHIEVEMENTS[banner_id].get("medal", "nav_achievements")))
	if medal != null: banner.draw_texture_rect(medal, Rect2(box.position + Vector2(6, 3), Vector2(56, 56)), false)
	banner.draw_string(UIK.bold_font, box.position + Vector2(70, 25), Game.t("ACHIEVEMENT UNLOCKED", "LOGRO DESBLOQUEADO"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, UIK.MINT)
	banner.draw_string(UIK.title_font, box.position + Vector2(70, 49), Game.tt(info.name), HORIZONTAL_ALIGNMENT_LEFT, 308, 22, UIK.PAPER)
