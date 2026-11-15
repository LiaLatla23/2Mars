extends BaseScreen
## Presentación de marca (referencias 8-9) con carga REAL de recursos: el porcentaje es
## recursos cargados / recursos pedidos, no un temporizador. Después, la primera vez, pide
## idioma y modo de entrada.

const ASSETS := ["res://assets/brand/logo_2mars.png", "res://assets/fonts/Fredoka.ttf", "res://assets/fonts/Nunito.ttf", "res://assets/audio/music_base.ogg", "res://assets/audio/music_explore.ogg",
	"res://assets/audio/launch.wav", "res://shaders/globe.gdshader", "res://scripts/screens/menu.gd", "res://scripts/screens/hub.gd", "res://scripts/screens/design.gd",
	"res://scripts/screens/zones.gd", "res://scripts/screens/transit.gd", "res://scripts/screens/ops.gd", "res://scripts/screens/debrief.gd", "res://scripts/screens/library.gd"]

var loaded := 0
var shown := 0.0
var phase := "load"
var hold := 0.0
var box: Control

func _ready() -> void:
	backdrop = "space"
	logo(Rect2(340, 90, 600, 380))
	for path in ASSETS: ResourceLoader.load_threaded_request(path)

func tick(delta: float) -> void:
	if phase != "load": return
	loaded = 0
	for path in ASSETS:
		var status := ResourceLoader.load_threaded_get_status(path)
		if status == ResourceLoader.THREAD_LOAD_LOADED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE or status == ResourceLoader.THREAD_LOAD_FAILED: loaded += 1
	var target := float(loaded) / ASSETS.size()
	shown = target if Game.reduced_motion else move_toward(shown, target, delta * 1.6)
	if shown >= 0.999:
		hold += delta
		if hold > 0.35:
			if Game.setup_done: finish()
			else: show_setup()

func show_setup() -> void:
	phase = "setup"
	if is_instance_valid(box): box.queue_free()
	box = UIK.panel(self, Rect2(290, 440, 700, 250))
	var column := UIK.column(box, Rect2(24, 14, 652, 222), 8)
	UIK.label(column, "Language · Idioma", 15, UIK.MUTED, "bold")
	var langs := UIK.row(column, 10)
	for id in ["en", "es"]:
		var b := UIK.button(langs, "English" if id == "en" else "Español", func() -> void: set_lang(id), "primary" if Game.lang == id else "ghost", Vector2(200, 44))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.label(column, Game.t("How do you want to play?", "¿Cómo quieres jugar?"), 15, UIK.MUTED, "bold")
	var modes := UIK.row(column, 10)
	var names := {"mouse": Game.t("Mouse", "Ratón"), "keyboard": Game.t("Keyboard", "Teclado"), "both": Game.t("Mouse + keyboard", "Ratón + teclado")}
	for id in ["mouse", "keyboard", "both"]:
		var b := UIK.button(modes, names[id], func() -> void: set_mode(id), "primary" if Game.input_mode == id else "ghost", Vector2(180, 44))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var go := UIK.button(column, Game.t("Continue", "Continuar"), confirm_setup, "go", Vector2(260, 50))
	go.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(go.get_parent())
	if Game.input_mode != "mouse": go.grab_focus.call_deferred()

func set_lang(id: String) -> void:
	Game.lang = id
	show_setup()

func set_mode(id: String) -> void:
	Game.input_mode = id
	show_setup()

func confirm_setup() -> void:
	Game.setup_done = true
	Game.save()
	finish()

func finish() -> void:
	if phase == "done": return
	phase = "done"
	Game.go("menu")

func paint() -> void:
	if phase != "load": return
	var bar := Rect2(390, 560, 500, 30)
	draw_style_box(UIK.box(UIK.INK, 15, UIK.INK, 4, 0), bar.grow(4))
	UIK.bar(self, bar, shown, UIK.CREAM, Color(UIK.NAVY, 0.9))
	var text := Game.t("Loading %d%%", "Cargando %d%%") % int(shown * 100.0)
	draw_string_outline(UIK.title_font, Vector2(390, 540), text, HORIZONTAL_ALIGNMENT_CENTER, 500, 26, 8, UIK.INK)
	draw_string(UIK.title_font, Vector2(390, 540), text, HORIZONTAL_ALIGNMENT_CENTER, 500, 26, UIK.PAPER)
