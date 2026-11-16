extends BaseScreen
## Logros (referencia 2, V4): galería de medallas propias. La elegida se ve en grande con su
## requisito y un contador real. Los 17 logros y sus condiciones son los de V3.

var selected := "first_launch"
var grid: GridContainer
var detail: VBoxContainer

func _ready() -> void:
	stage_backdrop("vista")
	shade(Rect2(0, 0, 1280, 720), Color(UIK.INK, 0.4))
	logo(Rect2(20, 6, 190, 120))
	title(Game.t("ACHIEVEMENTS: %d/%d", "LOGROS: %d/%d") % [Game.achievements.size(), Data.ACHIEVEMENT_ORDER.size()], Vector2(470, 24), 40)
	back_button(Game.t("GO BACK", "VOLVER"), "menu" if not Game.any_slot_used() or Game.player_name == "" else "hub", Vector2(1096, 24))
	var left := UIK.panel(self, Rect2(28, 136, 330, 556), UIK.ORANGE, 26)
	detail = UIK.column(left, Rect2(20, 18, 290, 520), 8)
	var right := UIK.panel(self, Rect2(378, 136, 874, 556), UIK.ORANGE, 26)
	var holder := ScrollContainer.new()
	holder.position = Vector2(16, 16)
	holder.size = Vector2(842, 524)
	holder.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	holder.follow_focus = true
	right.add_child(holder)
	grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	holder.add_child(grid)
	for id in Data.ACHIEVEMENT_ORDER:
		if Game.achievements.has(id):
			selected = id
			break
	refresh(true)
	Motion.slide_in(left, Vector2(-40, 0))

## Progreso medible de un logro: [valor, objetivo].
func counter(id: String) -> Array:
	match id:
		"all_zones":
			var done := 0
			for zone in Data.ZONE_ORDER:
				if Game.progress.has(zone) and String(Game.progress[zone].get("grade", "D")) in ["S", "A", "B", "C"]: done += 1
			return [done, Data.ZONE_ORDER.size()]
		"historian": return [mini(Game.stories.size(), Data.STORY_ORDER.size()), Data.STORY_ORDER.size()]
	return [1 if Game.achievements.has(id) else 0, 1]

func refresh(animate: bool = false) -> void:
	for child in grid.get_children(): child.queue_free()
	var shown: Array = []
	for id in Data.ACHIEVEMENT_ORDER:
		var info: Dictionary = Data.ACHIEVEMENTS[id]
		var got := Game.achievements.has(id)
		var secret: bool = bool(info.get("hidden", false)) and not got
		var key: String = id
		var card := UIK.tile(grid, Vector2(158, 164), func() -> void: pick(key), {"image": UIK.tex("pin_locked" if secret else String(info.medal)), "title": "???" if secret else Game.tt(info.name),
			"tile": Color("#293746") if got else Color("#b9b2a2"), "accent": UIK.CREAM, "selected": id == selected, "done": got})
		if not got and not secret:
			for child in card.get_children():
				if child is TextureRect and (child as TextureRect).texture == UIK.tex(String(info.medal)): (child as TextureRect).modulate = Color(0.55, 0.55, 0.6, 0.6)
		shown.append(card)
	if animate: Motion.stagger(shown)
	show_detail()

func pick(id: String) -> void:
	selected = id
	refresh()

func show_detail() -> void:
	for child in detail.get_children(): child.queue_free()
	var info: Dictionary = Data.ACHIEVEMENTS[selected]
	var got := Game.achievements.has(selected)
	var secret: bool = bool(info.get("hidden", false)) and not got
	var plate := PanelContainer.new()
	plate.add_theme_stylebox_override("panel", UIK.box(Color("#293746") if got else Color("#b9b2a2"), 22, UIK.INK, 3, 4))
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	detail.add_child(plate)
	var art := UIK.picture(plate, UIK.tex("pin_locked" if secret else String(info.medal)), Vector2(210, 210))
	if not got and not secret: art.modulate = Color(0.55, 0.55, 0.6, 0.6)
	if got: Motion.celebrate(art)
	var name_label := UIK.text(detail, "???" if secret else Game.tt(info.name), 28, UIK.INK)
	name_label.add_theme_font_override("font", UIK.title_font)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var how := UIK.text(detail, Game.t("A hidden achievement. Stay curious.", "Un logro oculto. Mantén la curiosidad.") if secret else Game.tt(info.how), 17, UIK.INK)
	how.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.add_child(spacer)
	var count := counter(selected)
	var line := UIK.row(detail, 8)
	UIK.label(line, Game.t("PROGRESS", "PROGRESO"), 15, UIK.INK, "bold")
	UIK.gauge(line, float(count[0]) / maxf(1.0, float(count[1])), UIK.GO, 18.0, Color(UIK.INK, 0.25))
	UIK.label(line, "%d/%d" % [int(count[0]), int(count[1])], 17, UIK.INK, "title")
	var state := UIK.chip(detail, Game.t("  UNLOCKED  ", "  DESBLOQUEADO  ") if got else Game.t("  LOCKED  ", "  BLOQUEADO  "), UIK.GOOD if got else UIK.NAVY)
	state.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	state.add_theme_font_size_override("font_size", 16)
