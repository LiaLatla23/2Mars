extends BaseScreen
## Briefing de misión con la Dra. Owen (guion del equipo, fase 1): presentación, nombres,
## los seis factores conectados, cómo se juega y objetivos requeridos frente a opcionales.

var step := 0
var stage: Control
var name_box: LineEdit
var rover_box: LineEdit
var mission_box: LineEdit
var factor_note: Label
var hovered := -1

func _ready() -> void:
	backdrop = "space"
	backdrop_dim = 0.35
	logo(Rect2(20, 6, 190, 122))
	var skip := UIK.button(self, Game.t("Skip briefing", "Saltar briefing"), finish, "ghost", Vector2(190, 42))
	skip.position = Vector2(1066, 24)
	skip.focus_mode = Control.FOCUS_NONE
	show_step()

func show_step() -> void:
	if is_instance_valid(stage): stage.queue_free()
	stage = Control.new()
	stage.set_anchors_preset(Control.PRESET_FULL_RECT)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	var dots := UIK.row(stage, 8)
	dots.position = Vector2(590, 36)
	for i in range(4): UIK.chip(dots, " %d " % (i + 1), UIK.ORANGE if i == step else (UIK.MINT if i < step else UIK.NAVY))
	var rover := Game.rover_name
	var text := ""
	match step:
		0: text = Game.t("Ah! Just in time. Welcome to team %s. I'm Dr. Owen, director of systems integration, and I'll be supervising your first mission. Before we begin: what should I call you?", "¡Ah! Justo a tiempo. Bienvenido al equipo %s. Soy la Dra. Owen, directora de integración de sistemas, y supervisaré tu primera misión. Antes de empezar: ¿cómo debería llamarte?") % Game.team_name
		1: text = Game.t("Perfect, %s. Now, to work. Our destination is Mars: a region of interest in Jezero Crater. Give our robotic explorer and this mission a name.", "Perfecto, %s. Ahora sí, al trabajo. Nuestro destino es Marte: una región de interés en el cráter Jezero. Ponle nombre a nuestro explorador robótico y a esta misión.") % Game.player_name
		2: text = Game.t("%s will explore the terrain, analyse samples and send home what it learns. But building a rover is not enough: all its systems must work together. These six factors stay connected all mission long. A better instrument finds more, and it also adds mass, cost and energy use. No design is perfect for everything.", "%s explorará el terreno, analizará muestras y enviará a casa lo que aprenda. Pero construir un rover no basta: todos sus sistemas deben funcionar juntos. Estos seis factores estarán conectados toda la misión. Un instrumento mejor descubre más, y también añade masa, costo y consumo. Ningún diseño es perfecto para todo.") % rover
		3: text = Game.t("Your mission: design, prepare and operate %s. And don't worry if something goes wrong. In engineering, finding a problem is part of the job. What matters is understanding what happened and deciding how to respond. I'll leave you in the lab.", "Tu misión: diseñar, preparar y operar a %s. Y no te preocupes si algo sale mal. En ingeniería, detectar un problema también es parte del trabajo. Lo importante es entender qué ocurrió y decidir cómo responder. Te dejo en el laboratorio.") % rover
	var owen := owen_panel(stage, Rect2(140, 490, 1000, 212), text, Game.t("Systems integration", "Integración de sistemas"))
	var column: VBoxContainer = owen.column
	var buttons := UIK.row(column, 10)
	match step:
		0:
			var card := UIK.panel(stage, Rect2(390, 250, 500, 150))
			var inner := UIK.column(card, Rect2(24, 18, 452, 120), 8)
			UIK.label(inner, Game.t("YOUR NAME", "TU NOMBRE"), 14, UIK.MUTED, "bold")
			name_box = UIK.field(inner, Game.player_name, 16, Game.t("Commander", "Comandante"))
			name_box.text_submitted.connect(func(_t: String) -> void: next())
			name_box.grab_focus.call_deferred()
		1:
			var card := UIK.panel(stage, Rect2(340, 190, 600, 250))
			var inner := UIK.column(card, Rect2(24, 18, 552, 220), 8)
			UIK.label(inner, Game.t("ROVER NAME", "NOMBRE DEL ROVER"), 14, UIK.MUTED, "bold")
			rover_box = UIK.field(inner, Game.rover_name, 14, "ARES 01")
			UIK.label(inner, Game.t("MISSION NAME", "NOMBRE DE LA MISIÓN"), 14, UIK.MUTED, "bold")
			mission_box = UIK.field(inner, Game.mission_name, 22, Game.t("Jezero One", "Jezero Uno"))
			mission_box.text_submitted.connect(func(_t: String) -> void: next())
			rover_box.grab_focus.call_deferred()
		2:
			var grid := GridContainer.new()
			grid.columns = 3
			grid.position = Vector2(200, 150)
			grid.add_theme_constant_override("h_separation", 16)
			grid.add_theme_constant_override("v_separation", 14)
			stage.add_child(grid)
			for i in range(Data.FACTORS.size()):
				var factor: Dictionary = Data.FACTORS[i]
				var cell := UIK.button(grid, "", func() -> void: explain(i), "yellow", Vector2(282, 112))
				cell.mouse_entered.connect(func() -> void: explain(i))
				cell.focus_entered.connect(func() -> void: explain(i))
				cell.draw.connect(func() -> void:
					cell.draw_circle(Vector2(52, 56), 34, UIK.ORANGE)
					Art.icon(cell, String(factor.id), Vector2(52, 56), 40, UIK.INK)
					cell.draw_string(UIK.title_font, Vector2(100, 66), Game.tt(factor.name), HORIZONTAL_ALIGNMENT_LEFT, 176, 24, UIK.INK))
				UIK.pop(cell, 0.12 * i)
			factor_note = UIK.heading(stage, Game.t("Point at a factor to see what it limits.", "Señala un factor para ver qué limita."), 20)
			factor_note.position = Vector2(200, 414)
			factor_note.size = Vector2(880, 60)
			factor_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		3:
			var card := UIK.panel(stage, Rect2(170, 140, 940, 330))
			var inner := UIK.column(card, Rect2(28, 18, 884, 300), 8)
			UIK.label(inner, Game.t("HOW TO PLAY", "CÓMO SE JUEGA"), 26, UIK.NAVY, "title")
			for line in [
				[Game.t("1  DESIGN", "1  DISEÑA"), Game.t("Plan the mission and build the rover inside its mass and budget limits.", "Planifica la misión y construye el rover dentro de sus límites de masa y presupuesto.")],
				[Game.t("2  OPERATE", "2  OPERA"), Game.t("Launch, land and drive on Mars. Study rocks with the instruments you brought.", "Lanza, aterriza y conduce en Marte. Estudia rocas con los instrumentos que llevaste.")],
				[Game.t("3  TRANSMIT", "3  TRANSMITE"), Game.t("Send your data home. Science only counts when Earth receives it.", "Envía tus datos a casa. La ciencia solo cuenta cuando la Tierra la recibe.")]]:
				var row := UIK.row(inner, 12)
				UIK.chip(row, " %s " % String(line[0]), UIK.ORANGE).custom_minimum_size.x = 150
				UIK.text(row, String(line[1]), 18, UIK.INK)
			var goals := UIK.row(inner, 14)
			var required := UIK.card(goals, Game.t("REQUIRED OBJECTIVES", "OBJETIVOS REQUERIDOS"), UIK.ORANGE)
			UIK.text(required, Game.t("They decide whether the mission is complete. Finish them and you may end the mission.", "Deciden si la misión está completa. Al cumplirlos puedes terminar la misión."), 16, UIK.INK)
			var optional := UIK.card(goals, Game.t("OPTIONAL OBJECTIVES", "OBJETIVOS OPCIONALES"), UIK.MINT)
			UIK.text(optional, Game.t("Extra science and achievements. Never needed to finish.", "Ciencia extra y logros. Nunca son necesarios para terminar."), 16, UIK.INK)
	if step > 0: UIK.button(buttons, Game.t("← Back", "← Atrás"), back, "ghost", Vector2(120, 40))
	if step < 3: UIK.button(buttons, Game.t("Continue", "Continuar"), next, "go", Vector2(200, 40))
	else:
		UIK.button(buttons, Game.t("Thanks. To the lab!", "Gracias. ¡Al laboratorio!"), finish, "go", Vector2(250, 40))
		wait_button(buttons)
	if step >= 2: UIK.focus_first(buttons)

func explain(index: int) -> void:
	hovered = index
	if is_instance_valid(factor_note): factor_note.text = "%s: %s" % [Game.tt(Data.FACTORS[index].name), Game.tt(Data.FACTORS[index].note)]

func store() -> void:
	if step == 0 and is_instance_valid(name_box):
		var typed := name_box.text.strip_edges()
		Game.player_name = typed if typed != "" else Game.t("Commander", "Comandante")
	if step == 1 and is_instance_valid(rover_box):
		var rover := rover_box.text.strip_edges()
		Game.rover_name = rover if rover != "" else "ARES 01"
		var mission := mission_box.text.strip_edges()
		Game.mission_name = mission if mission != "" else Game.t("Jezero One", "Jezero Uno")

func next() -> void:
	store()
	step = mini(step + 1, 3)
	show_step()

func back() -> void:
	store()
	step = maxi(step - 1, 0)
	show_step()

func finish() -> void:
	store()
	if Game.player_name == "": Game.player_name = Game.t("Commander", "Comandante")
	if Game.mission_name == "": Game.mission_name = Game.t("Jezero One", "Jezero Uno")
	Game.tutorial["intro"] = true
	Game.save()
	Game.go("hub")
