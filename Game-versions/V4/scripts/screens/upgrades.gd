extends BaseScreen
## Mejoras (referencia 18, V4). Tarjetas ilustradas con coste, requisito, estado y beneficio.
## Cada mejora cambia una regla real del modelo de juego (ver Data.UPGRADES y Data.up),
## se guarda en el archivo y se paga con puntos de ciencia recibidos en la Tierra.

const GOLD := Color("#f6c945")
var area := "all"
var selected := "treads"
var grid: GridContainer
var detail: VBoxContainer
var points_label: Label
var tabs := {}

func _ready() -> void:
	stage_backdrop("workshop")
	scene3d.goal = Vector3(2.3, 0.2, 13.0)
	scene3d.orbit = scene3d.goal
	shade(Rect2(0, 0, 1280, 720), Color(UIK.INK, 0.45))
	title(Game.t("UPGRADES", "MEJORAS"), Vector2(28, 12), 44).add_theme_color_override("font_color", GOLD)
	var sub := UIK.label(self, Game.t("Invest the science you brought home", "Invierte la ciencia que trajiste a casa"), 17, UIK.PAPER, "bold")
	sub.position = Vector2(32, 66)
	back_button(Game.t("GO BACK", "VOLVER"), "hub", Vector2(1096, 20))
	var wallet := UIK.panel(self, Rect2(820, 18, 256, 52), UIK.NAVY, 18)
	UIK.picture(wallet, UIK.tex("nav_research"), Vector2(40, 40)).position = Vector2(8, 6)
	points_label = UIK.label(wallet, "", 20, UIK.CREAM, "title")
	points_label.position = Vector2(54, 4)
	UIK.label(wallet, Game.t("science points", "puntos de ciencia"), 12, UIK.MINT, "bold").position = Vector2(56, 30)
	var left := UIK.panel(self, Rect2(24, 100, 760, 600), GOLD, 26)
	var filters := UIK.row(left, 8)
	filters.position = Vector2(18, 14)
	for id in ["all", "rover", "research", "infra"]:
		var key: String = id
		var caption := Game.t("All", "Todas") if id == "all" else Game.tt(Data.UPGRADE_AREAS[id])
		var b := UIK.button(filters, caption, func() -> void: open_area(key), "ghost", Vector2(150, 40))
		b.add_theme_font_size_override("font_size", 16)
		tabs[id] = b
	grid = GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.position = Vector2(18, 68)
	left.add_child(grid)
	var note := UIK.text(left, Game.t("Game values. Sandbox ignores upgrades.", "Valores de juego. Sandbox no aplica las mejoras."), 13, UIK.INK, 720)
	note.position = Vector2(20, 566)
	note.size = Vector2(720, 22)
	var right := UIK.panel(self, Rect2(800, 100, 456, 600), UIK.PAPER, 26)
	detail = UIK.column(right, Rect2(24, 18, 408, 564), 8)
	open_area("all")
	Motion.slide_in(left, Vector2(-40, 0))
	Motion.slide_in(right, Vector2(40, 0))

func open_area(id: String) -> void:
	area = id
	for key in tabs: (tabs[key] as Button).add_theme_stylebox_override("normal", UIK.box(UIK.NAVY if key == id else UIK.PAPER, 16, UIK.INK, 3, 3))
	for key in tabs:
		for state in ["font_color", "font_hover_color", "font_focus_color"]: (tabs[key] as Button).add_theme_color_override(state, UIK.PAPER if key == id else UIK.INK)
	refresh(true)

func refresh(animate: bool = false) -> void:
	points_label.text = "%d" % Game.science_points()
	for child in grid.get_children(): child.queue_free()
	var shown: Array = []
	for id in Data.UPGRADE_ORDER:
		var info: Dictionary = Data.UPGRADES[id]
		if area != "all" and String(info.area) != area: continue
		var state := Game.upgrade_state(id)
		var key: String = id
		var tag := {"owned": Game.t("installed", "instalada"), "locked": Game.t("locked", "bloqueada"), "ready": "%d" % int(info.cost), "short": "%d" % int(info.cost)}[state] as String
		var card := UIK.tile(grid, Vector2(170, 150), func() -> void: pick(key), {"image": UIK.tex(String(info.icon)), "title": Game.tt(info.name), "tile": Color("#fff5dc") if state != "locked" else Color("#cfc8b8"),
			"accent": GOLD, "selected": id == selected, "locked": state == "locked", "done": state == "owned", "tag": tag, "tag_color": UIK.GO if state == "ready" else (UIK.TEAL if state == "owned" else UIK.NAVY)})
		shown.append(card)
	if animate: Motion.stagger(shown)
	if not Data.UPGRADES.has(selected) or (area != "all" and String(Data.UPGRADES[selected].area) != area):
		for id in Data.UPGRADE_ORDER:
			if area == "all" or String(Data.UPGRADES[id].area) == area:
				selected = id
				break
	show_detail()

func pick(id: String) -> void:
	selected = id
	refresh()

func show_detail() -> void:
	for child in detail.get_children(): child.queue_free()
	var info: Dictionary = Data.UPGRADES[selected]
	var state := Game.upgrade_state(selected)
	var head := UIK.row(detail, 14)
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UIK.box(GOLD, 20, UIK.INK, 3, 4))
	head.add_child(plate)
	var art := UIK.picture(plate, UIK.tex(String(info.icon)), Vector2(124, 124))
	Motion.celebrate(art)
	var words := UIK.column(head, Rect2(0, 0, 0, 0), 2)
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.chip(words, " %s " % Game.tt(Data.UPGRADE_AREAS[String(info.area)]).to_upper(), UIK.NAVY)
	var name_label := UIK.text(words, Game.tt(info.name), 26, UIK.NAVY)
	name_label.add_theme_font_override("font", UIK.title_font)
	UIK.text(detail, Game.tt(info.benefit), 18, UIK.INK).add_theme_font_override("font", UIK.bold_font)
	# antes y después con cifras reales del modelo
	var delta := Data.upgrade_delta(selected)
	var compare := UIK.card(detail, Game.t("BEFORE  →  AFTER", "ANTES  →  DESPUÉS"), GOLD, UIK.CREAM)
	UIK.label(compare, String(delta[0]), 15, UIK.NAVY, "bold")
	var top := maxf(float(delta[1]), float(delta[2]))
	for pair in [[Game.t("now", "ahora"), float(delta[1]), UIK.MUTED], [Game.t("upgraded", "con mejora"), float(delta[2]), UIK.GO]]:
		var line := UIK.row(compare, 8)
		UIK.label(line, String(pair[0]), 13, UIK.INK, "bold").custom_minimum_size.x = 86
		UIK.gauge(line, float(pair[1]) / maxf(1.0, top), pair[2], 14.0)
		UIK.label(line, "%d %s" % [int(pair[1]), String(delta[3])], 14, UIK.INK, "bold").custom_minimum_size.x = 118
	UIK.text(detail, Game.t("Inspired by: ", "Se inspira en: ") + Game.tt(info.real), 14, UIK.TEAL)
	var need := String(info.need)
	var facts := UIK.row(detail, 8)
	UIK.chip(facts, " %s %d " % [Game.t("COST", "COSTE"), int(info.cost)], UIK.RUST)
	if need != "": UIK.chip(facts, " %s: %s " % [Game.t("NEEDS", "REQUIERE"), Game.tt(Data.ZONES[need].name)], UIK.GOOD if state != "locked" else UIK.BAD)
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	var caption := {"owned": Game.t("INSTALLED ✓", "INSTALADA ✓"), "locked": Game.t("Complete %s first", "Completa antes %s") % (Game.tt(Data.ZONES[need].name) if need != "" else ""),
		"short": Game.t("You need %d more points", "Te faltan %d puntos") % (int(info.cost) - Game.science_points()), "ready": Game.t("UPGRADE!", "¡MEJORAR!")}[state] as String
	var buy := UIK.button(detail, caption, purchase, "go", Vector2(408, 64))
	buy.add_theme_font_size_override("font_size", 24 if state == "ready" else 18)
	buy.disabled = state != "ready"
	if state == "short": UIK.text(detail, Game.t("Science points come from data received on Earth. Fly a mission and transmit more.", "Los puntos de ciencia salen de los datos recibidos en la Tierra. Vuela una misión y transmite más."), 13, UIK.MUTED)

func purchase() -> void:
	if Game.buy_upgrade(selected):
		refresh()
		Motion.celebrate(points_label)
	else: Game.sfx("error")
