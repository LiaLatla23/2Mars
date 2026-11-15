extends Control
## Menú principal: paisaje low-poly animado y accesos.

var time := 0.0

func _ready() -> void:
	var has_progress := not Game.progress.is_empty()
	var column := UIK.column(self, Rect2(96, 286, 300, 380), 10)
	UIK.button(column, Game.t("Continue mission", "Continuar misión") if has_progress else Game.t("Start mission", "Iniciar misión"), func() -> void: Game.go("zones"), "primary", Vector2(300, 62))
	if has_progress: UIK.button(column, Game.t("New game", "Partida nueva"), new_game, "ghost", Vector2(300, 46))
	UIK.button(column, Game.t("Science library", "Biblioteca científica"), func() -> void: Game.go("library"), "teal", Vector2(300, 52))
	UIK.button(column, "English" if Game.lang == "es" else "Español", toggle_language, "ghost", Vector2(300, 46))
	UIK.button(column, sound_caption(), toggle_sound, "ghost", Vector2(300, 46))
	UIK.button(column, Game.t("Quit", "Salir"), func() -> void: get_tree().quit(), "ghost", Vector2(300, 46))
	var tagline := UIK.label(self, Game.t("Design your mission. Operate your rover. Discover Mars.", "Diseña tu misión. Opera tu rover. Descubre Marte."), 26, UIK.PAPER, "bold")
	tagline.position = Vector2(100, 232)
	var note := UIK.label(self, Game.t("Team SpaceNuts · NASA Space Apps Challenge 2026 · A fictional mission inspired by Mars 2020 Perseverance. Not affiliated with or endorsed by NASA.", "Equipo SpaceNuts · NASA Space Apps Challenge 2026 · Misión ficticia inspirada en Mars 2020 Perseverance. Sin afiliación ni respaldo de la NASA."), 14, Color(UIK.PAPER, 0.85))
	note.position = Vector2(100, 684)
	for i in range(column.get_child_count()): UIK.pop(column.get_child(i), 0.08 * i)

func sound_caption() -> String:
	return Game.t("Sound: on", "Sonido: sí") if Game.volume > 0.01 else Game.t("Sound: off", "Sonido: no")

func toggle_sound() -> void:
	Game.volume = 0.0 if Game.volume > 0.01 else 0.7
	Game.apply_volume()
	Game.save()
	Game.go("menu")

func new_game() -> void:
	Game.reset_progress()
	Game.go("zones")

func toggle_language() -> void:
	Game.lang = "en" if Game.lang == "es" else "es"
	Game.save()
	Game.go("menu")

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	Art.landscape(self, size, time)
	var drift := fmod(time * 14.0, size.x * 0.5)
	var rover_pos := Vector2(size.x * 0.48 + drift, size.y * 0.775 - sin(drift / size.x * TAU) * 14.0)
	for i in range(14):
		var back := rover_pos - Vector2(26.0 + i * 22.0, -6.0 + sin((drift - i * 22.0) / size.x * TAU) * -2.0)
		draw_rect(Rect2(back + Vector2(0, -38), Vector2(14, 6)), Color(0.45, 0.16, 0.12, 0.25 - i * 0.016))
		draw_rect(Rect2(back + Vector2(0, 42), Vector2(14, 6)), Color(0.45, 0.16, 0.12, 0.25 - i * 0.016))
	Art.rover(self, rover_pos, -0.05, Game.build, 3.0, time)
	draw_string(UIK.title_font, Vector2(98, 196), "ToMars", HORIZONTAL_ALIGNMENT_LEFT, -1, 132, Color(0.45, 0.16, 0.12, 0.45))
	draw_string(UIK.title_font, Vector2(92, 190), "ToMars", HORIZONTAL_ALIGNMENT_LEFT, -1, 132, UIK.PAPER)
