extends BaseScreen
## Colección de logros (referencia 2). El contador y el progreso son reales: salen del guardado.

var detail: Panel
var selected := ""

func _ready() -> void:
	backdrop = "space"
	backdrop_dim = 0.3
	logo(Rect2(20, 6, 190, 122))
	var total := Data.ACHIEVEMENT_ORDER.size()
	var have := Game.achievements.size()
	var head := UIK.heading(self, Game.t("ACHIEVEMENTS: %d/%d", "LOGROS: %d/%d") % [have, total], 40)
	head.position = Vector2(560, 40)
	back_button(Game.t("← Back", "← Volver"), "menu", Vector2(1096, 44))
	detail = UIK.panel(self, Rect2(40, 150, 300, 420), UIK.ORANGE)
	var grid_panel := UIK.panel(self, Rect2(370, 130, 870, 560), UIK.ORANGE)
	var content := UIK.scroll(grid_panel, Rect2(18, 18, 834, 524))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for id in Data.ACHIEVEMENT_ORDER:
		var info: Dictionary = Data.ACHIEVEMENTS[id]
		var got := Game.achievements.has(id)
		var secret := bool(info.get("hidden", false)) and not got
		var cell := UIK.button(grid, "", func() -> void: pick(id), "ghost" if got else "dark", Vector2(196, 112))
		cell.draw.connect(func() -> void:
			var c := Vector2(cell.size.x * 0.5, 42)
			cell.draw_circle(c, 28, UIK.ORANGE if got else Color(UIK.PAPER, 0.12))
			Art.icon(cell, "lock" if not got else String(info.icon), c, 34, UIK.INK if got else Color(UIK.PAPER, 0.5))
			cell.draw_string(UIK.bold_font, Vector2(6, 96), "???" if secret else Game.tt(info.name), HORIZONTAL_ALIGNMENT_CENTER, cell.size.x - 12, 15, UIK.INK if got else Color(UIK.PAPER, 0.75)))
	var bar_y := 600.0
	var label := UIK.heading(self, Game.t("PROGRESS  %d%%", "PROGRESO  %d%%") % int(100.0 * have / total), 22)
	label.position = Vector2(48, bar_y - 14)
	pick(Data.ACHIEVEMENT_ORDER[0])
	UIK.focus_first(grid)

func pick(id: String) -> void:
	selected = id
	for child in detail.get_children(): child.queue_free()
	var info: Dictionary = Data.ACHIEVEMENTS[id]
	var got := Game.achievements.has(id)
	var secret := bool(info.get("hidden", false)) and not got
	var art := Control.new()
	art.position = Vector2(30, 24)
	art.size = Vector2(240, 190)
	art.draw.connect(func() -> void:
		art.draw_style_box(UIK.box(UIK.PAPER if got else Color(UIK.NAVY, 0.9), 16, UIK.INK, 3, 0), Rect2(Vector2.ZERO, art.size))
		art.draw_circle(art.size * 0.5, 62, UIK.ORANGE if got else Color(UIK.PAPER, 0.12))
		Art.icon(art, "lock" if not got else String(info.icon), art.size * 0.5, 78, UIK.INK if got else Color(UIK.PAPER, 0.5)))
	detail.add_child(art)
	var column := UIK.column(detail, Rect2(24, 226, 252, 180), 6)
	UIK.label(column, "???" if secret else Game.tt(info.name), 24, UIK.INK, "title").autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	UIK.text(column, Game.t("A hidden achievement. Keep talking to Dr. Owen.", "Un logro oculto. Sigue conversando con la Dra. Owen.") if secret else Game.tt(info.how), 16, UIK.INK)
	UIK.chip(column, Game.t(" UNLOCKED ", " DESBLOQUEADO ") if got else Game.t(" LOCKED ", " BLOQUEADO "), UIK.GOOD if got else UIK.NAVY)

func paint() -> void:
	var total := Data.ACHIEVEMENT_ORDER.size()
	var have := Game.achievements.size()
	for i in range(4):
		var filled := float(have) / total > (i + 0.5) / 4.0
		draw_rect(Rect2(48 + i * 72, 624, 64, 30), UIK.PAPER if filled else Color(UIK.PAPER, 0.2))
