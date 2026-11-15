extends BaseScreen
## Archivos de guardado (referencia 3) y equipo de lanzamiento (referencia 4).
## Los resúmenes muestran progreso REAL leído del guardado.

var selected := 0
var detail: Panel
var files: VBoxContainer
var step := "files"
var team_box: LineEdit
var emblem := 0
var stage: Control

func _ready() -> void:
	backdrop = "space"
	backdrop_dim = 0.25
	logo(Rect2(20, 6, 190, 122))
	selected = Game.slot
	show_files()

func clear_stage() -> void:
	if is_instance_valid(stage): stage.queue_free()
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)

func show_files() -> void:
	step = "files"
	clear_stage()
	var head := UIK.heading(stage, Game.t("SELECT A FILE", "ELIGE UN ARCHIVO"), 40)
	head.position = Vector2(240, 40)
	files = UIK.column(stage, Rect2(90, 190, 420, 400), 16)
	for i in range(Game.SLOT_COUNT):
		var data: Dictionary = Game.slots[i]
		var used := bool(data.get("used", false))
		var file_name := (String(data.get("team", "")) if String(data.get("team", "")) != "" else Game.t("File %d", "Archivo %d") % (i + 1)) if used else Game.t("NEW FILE", "ARCHIVO NUEVO")
		var caption := "%s   ·   %d%%" % [file_name.to_upper(), Game.campaign_percent(data.get("progress", {}))] if used else file_name
		var b := UIK.button(files, caption, func() -> void: pick(i), "primary", Vector2(420, 70))
		b.add_theme_font_size_override("font_size", 24)
	var back := UIK.button(stage, Game.t("← Menu", "← Menú"), func() -> void: Game.go("menu"), "ghost", Vector2(160, 46))
	back.position = Vector2(90, 640)
	detail = UIK.panel(stage, Rect2(620, 170, 560, 480), UIK.ORANGE)
	pick(selected)
	UIK.focus_first(files)

func pick(index: int) -> void:
	selected = index
	for child in detail.get_children(): child.queue_free()
	var data: Dictionary = Game.slots[index]
	var used := bool(data.get("used", false))
	var column := UIK.column(detail, Rect2(30, 24, 500, 340), 10)
	if not used:
		UIK.label(column, Game.t("Empty file", "Archivo vacío"), 30, UIK.INK, "title")
		UIK.text(column, Game.t("Start a new campaign here: name your launch team, meet Dr. Owen and design your first rover mission.", "Empieza aquí una campaña nueva: nombra a tu equipo de lanzamiento, conoce a la Dra. Owen y diseña tu primera misión con rover."), 18, UIK.INK)
		var go := UIK.button(detail, Game.t("CREATE", "CREAR"), show_team, "go", Vector2(500, 70))
		go.position = Vector2(30, 380)
		go.add_theme_font_size_override("font_size", 30)
		return
	var progress: Dictionary = data.get("progress", {})
	var percent := Game.campaign_percent(progress)
	UIK.label(column, String(data.get("team", "")) if String(data.get("team", "")) != "" else Game.t("File %d", "Archivo %d") % (index + 1), 30, UIK.INK, "title")
	UIK.label(column, Game.t("PROGRESS   %d%%", "PROGRESO   %d%%") % percent, 20, UIK.INK, "bold")
	var bars := UIK.row(column, 8)
	for id in Data.ZONE_ORDER:
		var done: bool = progress.has(id) and String(progress[id].get("grade", "D")) in ["S", "A", "B", "C"]
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(84, 26)
		cell.color = UIK.PAPER if done else Color(UIK.INK, 0.25)
		bars.add_child(cell)
	var runs := 0
	var science := 0
	for id in progress:
		runs += int(progress[id].get("runs", 0))
		science += int(progress[id].get("science", 0))
	UIK.label(column, Game.t("ROVERS LAUNCHED:  %d", "ROVERS LANZADOS:  %d") % runs, 19, UIK.INK, "bold")
	UIK.label(column, Game.t("SCIENCE RECEIVED ON EARTH:  %d pts", "CIENCIA RECIBIDA EN LA TIERRA:  %d pts") % science, 19, UIK.INK, "bold")
	UIK.label(column, Game.t("ACHIEVEMENTS:  %d / %d", "LOGROS:  %d / %d") % [(data.get("achievements", {}) as Dictionary).size(), Data.ACHIEVEMENT_ORDER.size()], 19, UIK.INK, "bold")
	UIK.label(column, Game.t("ROVER:  %s", "ROVER:  %s") % String(data.get("rover_name", "ARES 01")), 19, UIK.INK, "bold")
	var go2 := UIK.button(detail, Game.t("CONTINUE", "CONTINUAR"), continue_file, "go", Vector2(360, 70))
	go2.position = Vector2(30, 380)
	go2.add_theme_font_size_override("font_size", 30)
	var erase := UIK.button(detail, Game.t("Erase", "Borrar"), ask_erase, "danger", Vector2(124, 70))
	erase.position = Vector2(406, 380)

func continue_file() -> void:
	Game.start_slot(selected, false)
	Game.coop = false
	Game.go("hub" if bool(Game.tutorial.get("intro", false)) else "briefing")

func ask_erase() -> void:
	var content := UIK.modal(self, Vector2(520, 250), Game.t("Erase this file?", "¿Borrar este archivo?"))
	UIK.text(content, Game.t("Its campaign progress, rovers and achievements will be lost. Sandbox data is not affected.", "Se perderán su progreso de campaña, rovers y logros. Los datos de Sandbox no se ven afectados."), 17, UIK.INK)
	var line := UIK.row(content, 12)
	UIK.button(line, Game.t("Keep it", "Conservar"), func() -> void: UIK.close_modal(self), "ghost", Vector2(220, 48))
	UIK.button(line, Game.t("Erase", "Borrar"), erase_file, "danger", Vector2(220, 48))
	UIK.focus_first(content)

func erase_file() -> void:
	Game.slots[selected] = Game.blank_slot()
	if Game.slot == selected: Game.select_slot(selected)
	Game.save()
	UIK.close_modal(self)
	show_files()

func show_team() -> void:
	step = "team"
	clear_stage()
	var head := UIK.heading(stage, Game.t("YOUR LAUNCH TEAM", "TU EQUIPO DE LANZAMIENTO"), 38)
	head.position = Vector2(240, 44)
	var left := UIK.column(stage, Rect2(110, 230, 420, 300), 12)
	UIK.heading(left, Game.t("TEAM NAME", "NOMBRE DEL EQUIPO"), 22)
	team_box = UIK.field(left, "", 18, Game.t("e.g. SpaceNuts", "p. ej. SpaceNuts"))
	UIK.text(left, Game.t("Dr. Owen will welcome you to this team. You will name yourself and your rover in the briefing.", "La Dra. Owen te dará la bienvenida a este equipo. Tu nombre y el del rover los darás en el briefing."), 16, UIK.PAPER)
	UIK.button(left, Game.t("GO BACK", "VOLVER"), show_files, "ghost", Vector2(200, 46)).size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var grid_panel := UIK.panel(stage, Rect2(640, 180, 540, 390), UIK.ORANGE)
	var caption := UIK.label(grid_panel, Game.t("PICK AN EMBLEM", "ELIGE UN EMBLEMA"), 16, UIK.INK, "bold")
	caption.position = Vector2(26, 14)
	for i in range(Art.EMBLEMS):
		var cell := Button.new()
		cell.position = Vector2(26 + (i % 3) * 166, 46 + (i / 3) * 166)
		cell.size = Vector2(156, 156)
		cell.focus_mode = Control.FOCUS_NONE if Game.input_mode == "mouse" else Control.FOCUS_ALL
		cell.add_theme_stylebox_override("normal", UIK.box(UIK.PAPER, 14, Color(UIK.INK, 0.6), 3, 2))
		cell.add_theme_stylebox_override("hover", UIK.box(UIK.CREAM, 14, UIK.INK, 4, 4))
		cell.add_theme_stylebox_override("focus", UIK.box(Color(UIK.CREAM, 0.0), 14, UIK.INK, 5, 0))
		cell.add_theme_stylebox_override("pressed", UIK.box(UIK.CREAM, 14, UIK.INK, 4, 0))
		cell.pressed.connect(func() -> void:
			emblem = i
			Game.sfx("attach"))
		cell.draw.connect(func() -> void:
			if emblem == i: cell.draw_style_box(UIK.box(Color(UIK.GO, 0.35), 14, UIK.GO, 5, 0), Rect2(Vector2.ZERO, cell.size))
			Art.emblem(cell, i, cell.size * 0.5, 54))
		grid_panel.add_child(cell)
		portraits.append(cell)
	var go := UIK.button(stage, Game.t("CONTINUE", "CONTINUAR"), create_file, "go", Vector2(360, 66))
	go.position = Vector2(730, 596)
	go.add_theme_font_size_override("font_size", 28)
	team_box.grab_focus.call_deferred()

func create_file() -> void:
	Game.start_slot(selected, true)
	var typed := team_box.text.strip_edges()
	Game.team_name = typed if typed != "" else "SpaceNuts"
	Game.emblem = emblem
	Game.coop = false
	Game.save()
	Game.go("briefing")
