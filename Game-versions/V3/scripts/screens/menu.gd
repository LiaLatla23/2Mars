extends BaseScreen
## Menú principal (referencias 1 y 7): marca, Marte girando despacio y accesos.

var settings: Node

func _ready() -> void:
	backdrop = "space"
	var art := logo(Rect2(340, 6, 600, 380))
	if not Game.reduced_motion:
		art.pivot_offset = art.size * 0.5
		var float_tween := art.create_tween().set_loops()
		float_tween.tween_property(art, "position:y", 14.0, 2.4).set_trans(Tween.TRANS_SINE)
		float_tween.tween_property(art, "position:y", 6.0, 2.4).set_trans(Tween.TRANS_SINE)
	var has_save := Game.any_slot_used()
	var column := UIK.column(self, Rect2(440, 380, 400, 300), 10)
	if has_save: UIK.button(column, Game.t("CONTINUE", "CONTINUAR"), func() -> void: Game.go("profiles"), "primary", Vector2(400, 62)).add_theme_font_size_override("font_size", 26)
	var start := UIK.button(column, Game.t("START NEW GAME", "PARTIDA NUEVA"), func() -> void: Game.go("profiles"), "primary" if not has_save else "yellow", Vector2(400, 54))
	start.add_theme_font_size_override("font_size", 22)
	var pair := UIK.row(column, 10)
	UIK.button(pair, Game.t("Achievements", "Logros"), func() -> void: Game.go("achievements"), "ghost", Vector2(195, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.button(pair, Game.t("Settings", "Ajustes"), open_settings, "ghost", Vector2(195, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pair2 := UIK.row(column, 10)
	UIK.button(pair2, Game.t("Sandbox", "Sandbox"), open_sandbox, "teal", Vector2(195, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.button(pair2, Game.t("Science library", "Biblioteca"), func() -> void:
		Game.library_return = "menu"
		Game.go("library"), "teal", Vector2(195, 46)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quit := UIK.button(self, Game.t("Quit", "Salir"), func() -> void: get_tree().quit(), "ghost", Vector2(110, 40))
	quit.position = Vector2(1146, 660)
	var team := UIK.label(self, "SpaceNuts", 18, Color(UIK.PAPER, 0.8), "title")
	team.position = Vector2(24, 676)
	for i in range(column.get_child_count()): UIK.pop(column.get_child(i), 0.07 * i)
	UIK.focus_first(column)

func open_settings() -> void:
	Settings.open(self, func() -> void: Game.go("menu"))

func open_sandbox() -> void:
	Game.mode = "sandbox"
	Game.coop = false
	Game.zone = String(Game.sandbox.get("zone", "geology"))
	Game.go("design")
