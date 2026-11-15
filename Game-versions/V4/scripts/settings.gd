class_name Settings
## Ajustes como diálogo modal reutilizable (menú, base y pausa): idioma, modo de entrada,
## audio por canales, movimiento reducido y controles.

static func open(host: Control, on_close: Callable) -> void:
	var content := UIK.modal(host, Vector2(800, 690), Game.t("Settings", "Ajustes"))
	content.add_theme_constant_override("separation", 4)
	var rebuild := func() -> void:
		UIK.close_modal(host)
		open.call_deferred(host, on_close)
	UIK.label(content, Game.t("LANGUAGE", "IDIOMA"), 13, UIK.MUTED, "bold")
	var langs := UIK.row(content, 10)
	for id in ["en", "es"]:
		UIK.button(langs, "English" if id == "en" else "Español", func() -> void:
			Game.lang = id
			rebuild.call(), "primary" if Game.lang == id else "ghost", Vector2(180, 40))
	UIK.label(content, Game.t("INPUT MODE", "MODO DE ENTRADA"), 13, UIK.MUTED, "bold")
	var modes := UIK.row(content, 10)
	var names := {"mouse": Game.t("Mouse", "Ratón"), "keyboard": Game.t("Keyboard", "Teclado"), "both": Game.t("Mouse + keyboard", "Ratón + teclado")}
	for id in ["mouse", "keyboard", "both"]:
		UIK.button(modes, names[id], func() -> void:
			Game.input_mode = id
			rebuild.call(), "primary" if Game.input_mode == id else "ghost", Vector2(180, 40))
	UIK.label(content, Game.t("AUDIO", "AUDIO"), 13, UIK.MUTED, "bold")
	for channel in [["volume", Game.t("Master", "General")], ["music_volume", Game.t("Music", "Música")], ["sfx_volume", Game.t("Effects", "Efectos")]]:
		var line := UIK.row(content, 10)
		var caption := UIK.label(line, String(channel[1]), 16, UIK.INK, "bold")
		caption.custom_minimum_size.x = 110
		var slider := HSlider.new()
		slider.min_value = 0.0
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = float(Game.get(channel[0]))
		slider.custom_minimum_size = Vector2(380, 26)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var key := String(channel[0])
		slider.value_changed.connect(func(value: float) -> void:
			Game.set(key, value)
			Game.apply_volume())
		slider.drag_ended.connect(func(_changed: bool) -> void: Game.sfx("click"))
		line.add_child(slider)
	var toggles := UIK.row(content, 10)
	UIK.button(toggles, Game.t("Mute: on", "Silencio: sí") if Game.volume <= 0.01 else Game.t("Mute: off", "Silencio: no"), func() -> void:
		Game.volume = 0.7 if Game.volume <= 0.01 else 0.0
		Game.apply_volume()
		rebuild.call(), "ghost", Vector2(200, 40))
	UIK.button(toggles, Game.t("Reduced motion: on", "Movimiento reducido: sí") if Game.reduced_motion else Game.t("Reduced motion: off", "Movimiento reducido: no"), func() -> void:
		Game.reduced_motion = not Game.reduced_motion
		rebuild.call(), "ghost", Vector2(280, 40))
	var replayed := not bool(Game.tutorial.get("workshop", false)) and not bool(Game.tutorial.get("ops", false))
	var replay := UIK.button(toggles, Game.t("Tutorials: will replay", "Tutoriales: se repetirán") if replayed else Game.t("Replay tutorials", "Repetir tutoriales"), func() -> void:
		for key in ["workshop", "workshop_step", "ops", "ops_step"]: Game.tutorial.erase(key)
		rebuild.call(), "ghost", Vector2(210, 40))
	replay.disabled = replayed
	UIK.label(content, Game.t("3D GRAPHICS · applies when a screen opens", "GRÁFICOS 3D · se aplica al abrir una pantalla"), 13, UIK.MUTED, "bold")
	var graphics := UIK.row(content, 10)
	var levels := [Game.t("Low", "Baja"), Game.t("Medium", "Media"), Game.t("High", "Alta")]
	for i in range(3):
		var level := i
		var b := UIK.button(graphics, String(levels[i]), func() -> void:
			Game.quality = level
			rebuild.call(), "primary" if Game.quality == i else "ghost", Vector2(130, 40))
		b.tooltip_text = [Game.t("60% render scale, no shadows, no outlines, still backgrounds", "Render al 60%, sin sombras ni contornos, fondos fijos"), Game.t("85% render scale, shadows and outlines", "Render al 85%, con sombras y contornos"), Game.t("Full resolution, shadows, outlines, 4x MSAA", "Resolución completa, sombras, contornos y MSAA 4x")][i]
	UIK.button(graphics, Game.t("Frame meter: on  [F3]", "Medidor de FPS: sí  [F3]") if Game.show_fps else Game.t("Frame meter: off  [F3]", "Medidor de FPS: no  [F3]"), func() -> void:
		Game.show_fps = not Game.show_fps
		rebuild.call(), "ghost", Vector2(250, 40))
	UIK.label(content, Game.t("CONTROLS", "CONTROLES"), 13, UIK.MUTED, "bold")
	# La tabla ocupa el espacio que queda; si no cabe, se desplaza en vez de salirse del panel.
	var area := ScrollContainer.new()
	area.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_child(area)
	var table := VBoxContainer.new()
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	area.add_child(table)
	controls(table, true)
	var done := UIK.button(content, Game.t("Done", "Listo"), func() -> void:
		Game.save()
		UIK.close_modal(host)
		on_close.call(), "go", Vector2(220, 48))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	UIK.focus_first(content)

## Tabla de controles según el modo de entrada elegido.
static func controls(parent: Node, compact: bool = false) -> void:
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 1 if compact else 4)
	parent.add_child(grid)
	var rows := [
		[Game.t("Drive", "Conducir"), "WASD / ↑↓←→", Game.t("hold the mouse button on the ground", "mantén el botón del ratón sobre el suelo")],
		[Game.t("Study a rock", "Estudiar una roca"), "E", Game.t("click the rock", "clic en la roca")],
		[Game.t("Choose / confirm", "Elegir / confirmar"), "1-6 · Enter", Game.t("click the button", "clic en el botón")],
		[Game.t("Instrument action", "Acción del instrumento"), Game.t("Space", "Espacio"), Game.t("click", "clic")],
		[Game.t("Transmit", "Transmitir"), "T", Game.t("Transmit button", "botón Transmitir")],
		[Game.t("Data · AutoNav · Help", "Datos · AutoNav · Ayuda"), "Tab · G · H", Game.t("action bar", "barra de acciones")],
		[Game.t("Weather · Oxygen · Radar", "Clima · Oxígeno · Radar"), "M · O · R", Game.t("action bar", "barra de acciones")],
		[Game.t("Pause / controls", "Pausa / controles"), "Esc", Game.t("Pause button", "botón Pausa")]
	]
	for item in rows:
		UIK.label(grid, String(item[0]), 14, UIK.INK, "bold").custom_minimum_size.x = 190
		var keys := UIK.chip(grid, " %s " % String(item[1]), UIK.NAVY)
		if compact:
			var style := keys.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.content_margin_top = 1
			style.content_margin_bottom = 1
			keys.add_theme_stylebox_override("normal", style)
		keys.modulate.a = 1.0 if Game.input_mode != "mouse" else 0.45
		UIK.label(grid, "·", 14, UIK.MUTED)
		UIK.label(grid, String(item[2]), 14, UIK.INK if Game.input_mode != "keyboard" else UIK.MUTED)
