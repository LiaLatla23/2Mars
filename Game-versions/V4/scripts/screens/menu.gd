extends BaseScreen
## Menú principal (referencias 1 y 7, V4): logotipo destacado, paisaje 3D de Marte con
## movimiento suave (vaivén de cámara, baliza, planeta) y acciones claras con iconos.

var settings: Node

func _ready() -> void:
	stage_backdrop("vista")
	var art := logo(Rect2(350, 2, 580, 368))
	if not Game.reduced_motion:
		var float_tween := art.create_tween().set_loops()
		float_tween.tween_property(art, "position:y", 12.0, 2.4).set_trans(Tween.TRANS_SINE)
		float_tween.tween_property(art, "position:y", 2.0, 2.4).set_trans(Tween.TRANS_SINE)
	var has_save := Game.any_slot_used()
	var column := UIK.column(self, Rect2(430, 372, 420, 330), 10)
	if has_save:
		var resume := UIK.icon_button(column, Game.t("CONTINUE", "CONTINUAR"), "nav_rovers", func() -> void: Game.go("profiles"), "primary", Vector2(420, 66))
		resume.add_theme_font_size_override("font_size", 28)
		resume.alignment = HORIZONTAL_ALIGNMENT_CENTER
		Motion.shine(resume, 4.5, 0.26)
	var start := UIK.icon_button(column, Game.t("START NEW GAME", "PARTIDA NUEVA"), "nav_launch", func() -> void: Game.go("profiles"), "primary" if not has_save else "yellow", Vector2(420, 58))
	start.add_theme_font_size_override("font_size", 24 if not has_save else 22)
	start.alignment = HORIZONTAL_ALIGNMENT_CENTER
	var pair := UIK.row(column, 10)
	UIK.icon_button(pair, Game.t("Achievements", "Logros"), "nav_achievements", func() -> void: Game.go("achievements"), "ghost", Vector2(205, 48)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.icon_button(pair, Game.t("Settings", "Ajustes"), "nav_settings", open_settings, "ghost", Vector2(205, 48)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var pair2 := UIK.row(column, 10)
	UIK.icon_button(pair2, Game.t("Sandbox", "Sandbox"), "nav_workshop", open_sandbox, "teal", Vector2(205, 48)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	UIK.icon_button(pair2, Game.t("Science library", "Biblioteca"), "nav_research", func() -> void:
		Game.library_return = "menu"
		Game.go("library"), "teal", Vector2(205, 48)).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var quit := UIK.button(self, Game.t("Quit", "Salir"), func() -> void: get_tree().quit(), "ghost", Vector2(110, 40))
	quit.position = Vector2(1146, 660)
	var team := UIK.heading(self, "SpaceNuts", 20, UIK.CREAM)
	team.position = Vector2(24, 672)
	var version := UIK.label(self, "V4 · %s" % String(ProjectSettings.get_setting("application/config/version", "")), 13, Color(UIK.PAPER, 0.8), "bold")
	version.position = Vector2(150, 682)
	Motion.stagger(column.get_children(), 0.035)
	UIK.focus_first(column)

func open_settings() -> void:
	Settings.open(self, func() -> void: Game.go("menu"))

func open_sandbox() -> void:
	Game.mode = "sandbox"
	Game.coop = false
	Game.zone = String(Game.sandbox.get("zone", "geology"))
	Game.go("design")
