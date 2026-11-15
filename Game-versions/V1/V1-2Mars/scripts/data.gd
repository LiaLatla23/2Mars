class_name Data
## Datos de diseño de ToMars. Los textos van en pares [inglés, español].
## Masa, créditos, MB y segundos son un MODELO EDUCATIVO del juego, no cifras de la NASA.
## Los datos reales de Perseverance están en REAL_FACTS / REAL_SAMPLES con su fuente.

const MASS_CAP := 80
const BUDGET := 110
const ZONE_ORDER := ["geology", "life", "archive", "frontier"]

const PARTS := {
	"power": {"title": ["Power source", "Fuente de energía"], "options": {
		"solar": {"name": ["Solar panels", "Paneles solares"], "mass": 8, "cost": 10, "note": ["Light and cheap. Charges fast in daylight, nothing at night; dust slowly covers the cells.", "Ligeros y baratos. Cargan rápido de día y nada de noche; el polvo cubre las celdas poco a poco."]},
		"rtg": {"name": ["Radioisotope (RTG)", "Radioisótopos (RTG)"], "mass": 20, "cost": 30, "note": ["Heavy and expensive. Steady power day and night, and its heat keeps the rover warm.", "Pesado y caro. Energía constante de día y de noche, y su calor mantiene tibio al rover."]}}},
	"battery": {"title": ["Battery", "Batería"], "options": {
		"small": {"name": ["Compact battery", "Batería compacta"], "mass": 6, "cost": 6, "note": ["100 units of stored energy.", "100 unidades de energía almacenada."]},
		"large": {"name": ["Extended battery", "Batería extendida"], "mass": 14, "cost": 14, "note": ["170 units: longer drives and more instrument use between charges.", "170 unidades: trayectos más largos y más uso de instrumentos entre cargas."]}}},
	"wheels": {"title": ["Mobility", "Movilidad"], "options": {
		"standard": {"name": ["Standard", "Estándar"], "mass": 10, "cost": 8, "note": ["Balanced speed. Sharp rocks wear them down.", "Velocidad equilibrada. Las rocas afiladas las desgastan."]},
		"rugged": {"name": ["Reinforced", "Reforzadas"], "mass": 16, "cost": 14, "note": ["Slower, but shrug off sharp terrain and soft sand.", "Más lentas, pero resisten el terreno afilado y la arena blanda."]},
		"light": {"name": ["Lightweight", "Ligeras"], "mass": 7, "cost": 12, "note": ["Fastest. Thin treads take double damage.", "Las más rápidas. Su banda fina recibe el doble de daño."]}}},
	"comms": {"title": ["Communications", "Comunicaciones"], "options": {
		"uhf": {"name": ["UHF relay antenna", "Antena UHF de relevo"], "mass": 4, "cost": 6, "note": ["Fast uplink, but only while an orbiter passes overhead.", "Envío rápido, pero solo mientras un orbitador pasa por encima."]},
		"hga": {"name": ["UHF + high-gain", "UHF + alta ganancia"], "mass": 9, "cost": 14, "note": ["Adds a slow direct link to Earth at any time.", "Añade un enlace lento y directo con la Tierra en cualquier momento."]}}},
	"computer": {"title": ["Data storage", "Almacenamiento de datos"], "options": {
		"standard": {"name": ["Standard memory", "Memoria estándar"], "mass": 3, "cost": 5, "note": ["70 MB. You must transmit often to free space.", "70 MB. Hay que transmitir a menudo para liberar espacio."]},
		"expanded": {"name": ["Expanded memory", "Memoria ampliada"], "mass": 5, "cost": 11, "note": ["160 MB. Room to keep working between orbiter passes.", "160 MB. Espacio para seguir trabajando entre pasos del orbitador."]}}}
}
const PART_ORDER := ["power", "battery", "wheels", "comms", "computer"]

## Instrumentos inspirados en los de Perseverance. "real" resume la función real (NASA);
## "game" explica qué hacen en el juego.
const INSTRUMENTS := {
	"mastcam": {"name": "Mastcam-Z", "mass": 4, "cost": 8, "energy": 3, "mb": 8, "science": 6, "range": 250, "arm": false, "mode": "focus",
		"real": ["Zoomable stereo cameras on the mast that image the terrain.", "Cámaras estéreo con zoom en el mástil que fotografían el terreno."],
		"game": ["Context image from a distance. Tells igneous from sedimentary rock and documents a site before sampling.", "Imagen de contexto a distancia. Distingue roca ígnea de sedimentaria y documenta el sitio antes de tomar una muestra."]},
	"supercam": {"name": "SuperCam", "mass": 10, "cost": 16, "energy": 8, "mb": 10, "science": 14, "range": 190, "arm": false, "mode": "timing",
		"real": ["Uses a laser and spectrometers to study rock composition from a distance.", "Usa un láser y espectrómetros para estudiar la composición de las rocas a distancia."],
		"game": ["Remote composition. Reveals the minerals in a rock without touching it.", "Composición a distancia. Revela los minerales de una roca sin tocarla."]},
	"arm": {"name": ["Robotic arm + drill", "Brazo robótico + taladro"], "mass": 12, "cost": 18, "energy": 14, "mb": 6, "science": 10, "range": 70, "arm": false, "mode": "steady",
		"real": ["A 2.1 m arm with a coring drill; samples are sealed in tubes.", "Un brazo de 2,1 m con un taladro de núcleos; las muestras se sellan en tubos."],
		"game": ["Needed by PIXL and SHERLOC. Cores and caches up to 4 samples.", "Lo necesitan PIXL y SHERLOC. Extrae y guarda hasta 4 muestras."]},
	"pixl": {"name": "PIXL", "mass": 7, "cost": 14, "energy": 10, "mb": 20, "science": 26, "range": 70, "arm": true, "mode": "steady",
		"real": ["X-ray instrument on the arm that maps the elemental chemistry of rocks.", "Instrumento de rayos X en el brazo que mapea la química elemental de las rocas."],
		"game": ["Contact chemistry. The most detailed geology data.", "Química por contacto. Los datos de geología más detallados."]},
	"sherloc": {"name": "SHERLOC", "mass": 5, "cost": 14, "energy": 12, "mb": 24, "science": 30, "range": 70, "arm": true, "mode": "steady",
		"real": ["Arm instrument that searches for organic molecules and minerals; WATSON is its camera.", "Instrumento del brazo que busca moléculas orgánicas y minerales; WATSON es su cámara."],
		"game": ["Contact search for organics. Key to astrobiology.", "Búsqueda de orgánicos por contacto. Clave para la astrobiología."]},
	"rimfax": {"name": "RIMFAX", "mass": 3, "cost": 9, "energy": 6, "mb": 18, "science": 22, "range": 0, "arm": false, "mode": "timing",
		"real": ["Ground-penetrating radar that images layers beneath the surface.", "Radar de penetración terrestre que muestra capas bajo la superficie."],
		"game": ["Scan buried layers at radar sites (press R on a site).", "Escanea capas enterradas en los sitios de radar (pulsa R sobre un sitio)."]},
	"meda": {"name": "MEDA", "mass": 5, "cost": 8, "energy": 0, "mb": 4, "science": 6, "range": 0, "arm": false, "mode": "",
		"real": ["Weather station: wind, temperature, pressure, humidity and dust.", "Estación meteorológica: viento, temperatura, presión, humedad y polvo."],
		"game": ["Logs weather while switched on (M) and warns before storms and dust devils.", "Registra el clima mientras está encendido (M) y avisa antes de tormentas y remolinos."]},
	"moxie": {"name": "MOXIE", "mass": 17, "cost": 20, "energy": 40, "mb": 16, "science": 40, "range": 0, "arm": false, "mode": "",
		"real": ["Technology demonstration that made oxygen from Mars' CO2 atmosphere. Not a life-support system.", "Demostración tecnológica que produjo oxígeno a partir del CO2 de Marte. No es un sistema de soporte vital."],
		"game": ["Run an oxygen experiment (O). Heavy and power-hungry.", "Ejecuta un experimento de oxígeno (O). Pesado y consume mucha energía."]}
}
const INSTRUMENT_ORDER := ["mastcam", "supercam", "arm", "pixl", "sherloc", "rimfax", "meda", "moxie"]

## Tipos de objetivo científico (rocas ficticias del juego, inspiradas en unidades de Jezero).
const ROCKS := {
	"basalt": {"name": ["Basaltic rock", "Roca basáltica"], "klass": "igneous", "color": "#6f5a57", "aqueous": false, "organics": false,
		"chem": ["Pyroxene and plagioclase: cooled lava.", "Piroxeno y plagioclasa: lava enfriada."]},
	"olivine": {"name": ["Olivine-rich rock", "Roca rica en olivino"], "klass": "igneous", "color": "#7d8a4f", "aqueous": false, "organics": false,
		"chem": ["Coarse olivine crystals that settled in a thick body of magma.", "Cristales gruesos de olivino que se asentaron en un cuerpo de magma."]},
	"mudstone": {"name": ["Delta mudstone", "Lutita del delta"], "klass": "sedimentary", "color": "#b58a6a", "aqueous": true, "organics": true,
		"chem": ["Fine clay-rich layers that settled in calm lake water.", "Capas finas ricas en arcilla que se depositaron en aguas tranquilas de lago."]},
	"sandstone": {"name": ["Delta sandstone", "Arenisca del delta"], "klass": "sedimentary", "color": "#c99a62", "aqueous": true, "organics": false,
		"chem": ["Sand grains carried and rounded by a river.", "Granos de arena transportados y redondeados por un río."]},
	"carbonate": {"name": ["Carbonate-bearing rock", "Roca con carbonatos"], "klass": "sedimentary", "color": "#d8c9a3", "aqueous": true, "organics": true,
		"chem": ["Carbonate minerals that form in water that is not too acidic.", "Minerales de carbonato que se forman en agua no demasiado ácida."]},
	"sulfate": {"name": ["Sulfate-bearing rock", "Roca con sulfatos"], "klass": "sedimentary", "color": "#e3d7c5", "aqueous": true, "organics": false,
		"chem": ["Sulfate salts left behind as salty water evaporated.", "Sales de sulfato que quedaron al evaporarse agua salada."]},
	"silica": {"name": ["Hydrated silica", "Sílice hidratada"], "klass": "sedimentary", "color": "#cfd9d6", "aqueous": true, "organics": true,
		"chem": ["Water-bearing silica, a material that preserves delicate traces well.", "Sílice con agua, un material que conserva bien rastros delicados."]},
	"regolith": {"name": ["Regolith patch", "Parche de regolito"], "klass": "soil", "color": "#b5674a", "aqueous": false, "organics": false,
		"chem": ["Loose dust and broken rock: what wheels, suits and habitats must deal with.", "Polvo suelto y roca triturada: con lo que lidian ruedas, trajes y hábitats."]}
}

const QUIZ := {
	"igneous": {"q": ["The rock is igneous. Why does the science team care?", "La roca es ígnea. ¿Por qué le importa al equipo científico?"],
		"options": [["It proves there was life here", "Demuestra que hubo vida aquí"], ["Igneous rocks can be dated, anchoring the crater's timeline", "Las rocas ígneas se pueden fechar y anclan la línea de tiempo del cráter"], ["It means water never existed here", "Significa que aquí nunca hubo agua"]], "correct": 1,
		"why": ["Lava rocks record when they cooled. They give the history of the region a clock.", "Las rocas de lava registran cuándo se enfriaron. Le dan un reloj a la historia de la región."]},
	"water": {"q": ["These minerals formed in liquid water. What can you conclude?", "Estos minerales se formaron en agua líquida. ¿Qué puedes concluir?"],
		"options": [["This place was once habitable: it had conditions life could have used", "Este lugar fue habitable: tuvo condiciones que la vida habría podido aprovechar"], ["Life existed here", "Aquí existió vida"], ["Nothing useful", "Nada útil"]], "correct": 0,
		"why": ["Habitability means the right conditions existed. It is not evidence that anything lived there.", "Habitabilidad significa que existieron las condiciones adecuadas. No es evidencia de que algo viviera allí."]},
	"organics": {"q": ["SHERLOC detects organic molecules. How should the result be reported?", "SHERLOC detecta moléculas orgánicas. ¿Cómo debe informarse el resultado?"],
		"options": [["Confirmed: ancient life on Mars", "Confirmado: vida antigua en Marte"], ["A potential biosignature: worth caching for labs on Earth", "Una posible biofirma: merece guardarse para laboratorios en la Tierra"], ["Contamination, ignore it", "Contaminación, ignóralo"]], "correct": 1,
		"why": ["Organic molecules can form without biology. NASA has not confirmed life on Mars; strong claims need laboratory study.", "Las moléculas orgánicas pueden formarse sin biología. La NASA no ha confirmado vida en Marte; una afirmación así exige estudio en laboratorio."]},
	"cache": {"q": ["Why image and record the site before sealing a sample?", "¿Por qué fotografiar y registrar el sitio antes de sellar una muestra?"],
		"options": [["Without context a sample is just a rock: where it came from tells scientists how to read it", "Sin contexto una muestra es solo una roca: su origen les dice a los científicos cómo interpretarla"], ["To make the tube lighter", "Para que el tubo pese menos"], ["It is only for publicity photos", "Solo sirve para fotos de prensa"]], "correct": 0,
		"why": ["Each sample is documented with its location, rock type and surroundings.", "Cada muestra se documenta con su ubicación, tipo de roca y entorno."]},
	"radar": {"q": ["The radar shows tilted layers below the surface. What are they?", "El radar muestra capas inclinadas bajo la superficie. ¿Qué son?"],
		"options": [["Buried strata that record how the terrain was built up over time", "Estratos enterrados que registran cómo se formó el terreno con el tiempo"], ["Underground cities", "Ciudades subterráneas"], ["Radio noise with no meaning", "Ruido de radio sin significado"]], "correct": 0,
		"why": ["Ground-penetrating radar reads the geology you cannot see from the surface.", "El radar de penetración lee la geología que no se ve desde la superficie."]},
	"moxie": {"q": ["The experiment produced oxygen from CO2. What does that mean?", "El experimento produjo oxígeno a partir de CO2. ¿Qué significa?"],
		"options": [["Astronauts can already live on Mars", "Los astronautas ya pueden vivir en Marte"], ["A technology demonstration: future missions could make oxygen in place", "Una demostración tecnológica: misiones futuras podrían producir oxígeno en el lugar"], ["Mars air is breathable", "El aire de Marte es respirable"]], "correct": 1,
		"why": ["MOXIE proved the method at small scale. It is not a life-support system.", "MOXIE probó el método a pequeña escala. No es un sistema de soporte vital."]},
	"weather": {"q": ["Why log wind, temperature and dust every day?", "¿Por qué registrar viento, temperatura y polvo todos los días?"],
		"options": [["Weather and dust records help design safe future missions", "Los registros de clima y polvo ayudan a diseñar misiones futuras seguras"], ["To predict rain", "Para predecir la lluvia"], ["Weather does not matter on Mars", "El clima no importa en Marte"]], "correct": 0,
		"why": ["Dust affects power, machines and people. Knowing the environment comes first.", "El polvo afecta la energía, las máquinas y a las personas. Conocer el entorno es lo primero."]}
}

const ZONES := {
	"geology": {"name": ["Crater Floor", "Suelo del cráter"], "goal": ["Geology", "Geología"], "color": "#e76f51", "ground": "#c66a47", "time": 300, "hazards": ["sharp"], "need_mb": 45,
		"nasa": ["Science objective: study the rocks and landscape to reveal the region's history.", "Objetivo científico: estudiar las rocas y el paisaje para revelar la historia de la región."],
		"brief": ["Lava rocks on the crater floor hold the oldest pages of this story. Document the rocks and find out what they are made of.", "Las rocas de lava del suelo del cráter guardan las páginas más antiguas de esta historia. Documenta las rocas y averigua de qué están hechas."],
		"rocks": {"basalt": 3, "olivine": 2, "regolith": 1}, "sites": 0, "suggest": ["mastcam", "supercam"],
		"objectives": [{"kind": "imaged", "need": 3, "text": ["Document 3 rocks with a context image", "Documenta 3 rocas con una imagen de contexto"]}, {"kind": "chem_types", "need": 2, "text": ["Get the composition of 2 different rock types", "Obtén la composición de 2 tipos de roca distintos"]}, {"kind": "received", "need": 45, "text": ["Receive 45 MB of science on Earth", "Recibe 45 MB de ciencia en la Tierra"]}]},
	"life": {"name": ["Ancient Delta", "Delta antiguo"], "goal": ["Search for Life", "Búsqueda de vida"], "color": "#2a9d8f", "ground": "#c98a5c", "time": 330, "hazards": ["devils", "sand"], "need_mb": 70,
		"nasa": ["Science objective: look for environments that were habitable and for signs of ancient microbial life.", "Objetivo científico: buscar ambientes que fueron habitables y señales de vida microbiana antigua."],
		"brief": ["A river once fed a lake here. Fine sediments are the best place to preserve traces. Find water-formed rocks and search them for organics.", "Un río alimentó un lago aquí. Los sedimentos finos son el mejor lugar para conservar rastros. Encuentra rocas formadas en agua y busca orgánicos en ellas."],
		"rocks": {"mudstone": 3, "sandstone": 2, "carbonate": 1, "basalt": 1}, "sites": 0, "suggest": ["supercam", "arm", "sherloc"],
		"objectives": [{"kind": "aqueous", "need": 2, "text": ["Identify 2 rocks that formed in water", "Identifica 2 rocas formadas en agua"]}, {"kind": "sherloc", "need": 2, "text": ["Search 2 rocks for organics with SHERLOC", "Busca orgánicos en 2 rocas con SHERLOC"]}, {"kind": "quiz", "need": 2, "text": ["Report 2 findings at the right level of certainty", "Informa 2 hallazgos con el nivel de certeza correcto"]}, {"kind": "received", "need": 70, "text": ["Receive 70 MB of science on Earth", "Recibe 70 MB de ciencia en la Tierra"]}]},
	"archive": {"name": ["Delta Margin", "Margen del delta"], "goal": ["Sample Archive", "Archivo de muestras"], "color": "#e9c46a", "ground": "#b9774f", "time": 360, "hazards": ["storm", "sharp", "devils"], "need_mb": 40,
		"nasa": ["Science objective: collect and document rock and regolith samples for possible return to Earth.", "Objetivo científico: recolectar y documentar muestras de roca y regolito para su posible retorno a la Tierra."],
		"brief": ["You carry only four tubes. Choose samples that tell different stories, and document every site before you drill.", "Solo llevas cuatro tubos. Elige muestras que cuenten historias distintas y documenta cada sitio antes de perforar."],
		"rocks": {"carbonate": 2, "sulfate": 1, "silica": 1, "mudstone": 1, "olivine": 1, "basalt": 1}, "sites": 0, "suggest": ["mastcam", "arm"],
		"objectives": [{"kind": "cache_types", "need": 3, "text": ["Cache 3 samples of different rock types", "Guarda 3 muestras de tipos de roca distintos"]}, {"kind": "cache_documented", "need": 3, "text": ["Document each site before coring (3)", "Documenta cada sitio antes de perforar (3)"]}, {"kind": "received", "need": 40, "text": ["Receive 40 MB of sample records on Earth", "Recibe 40 MB de registros de muestras en la Tierra"]}]},
	"frontier": {"name": ["Landing Plains", "Llanura de aterrizaje"], "goal": ["Human Frontier", "Frontera humana"], "color": "#457b9d", "ground": "#b9694a", "time": 360, "hazards": ["cold", "storm", "devils"], "need_mb": 55,
		"nasa": ["Science objective: prepare for human exploration by studying the environment and testing technology.", "Objetivo científico: preparar la exploración humana estudiando el ambiente y probando tecnología."],
		"brief": ["Before people arrive we must know the weather, the dust, the ground and whether oxygen can be made here.", "Antes de que llegue la gente hay que conocer el clima, el polvo, el suelo y si aquí se puede producir oxígeno."],
		"rocks": {"regolith": 3, "basalt": 2}, "sites": 2, "suggest": ["meda", "moxie", "rimfax"],
		"objectives": [{"kind": "meda", "need": 4, "text": ["Log 4 weather reports with MEDA", "Registra 4 informes meteorológicos con MEDA"]}, {"kind": "moxie", "need": 1, "text": ["Complete one MOXIE oxygen run", "Completa una prueba de oxígeno con MOXIE"]}, {"kind": "rimfax", "need": 1, "text": ["Scan one buried site with RIMFAX", "Escanea un sitio enterrado con RIMFAX"]}, {"kind": "received", "need": 55, "text": ["Receive 55 MB of science on Earth", "Recibe 55 MB de ciencia en la Tierra"]}]}
}

## Datos reales de Perseverance (NASA). Se muestran aparte de los valores del juego.
const REAL_FACTS := [
	["Perseverance carries seven science instruments: Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, MOXIE and RIMFAX.", "Perseverance lleva siete instrumentos científicos: Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, MOXIE y RIMFAX."],
	["The rover is about 3 m long, 2.7 m wide and 2.2 m tall, with a mass of about 1,025 kg.", "El rover mide unos 3 m de largo, 2,7 m de ancho y 2,2 m de alto, con una masa de unos 1.025 kg."],
	["Its power comes from an MMRTG that supplied about 110 W at the start of the mission and charges rechargeable batteries.", "Su energía viene de un MMRTG que daba unos 110 W al inicio de la misión y carga baterías recargables."],
	["Each wheel is about 52.5 cm in diameter; the suspension is a rocker-bogie.", "Cada rueda mide unos 52,5 cm de diámetro; la suspensión es de tipo rocker-bogie."],
	["The robotic arm is about 2.1 m long and has five degrees of freedom.", "El brazo robótico mide unos 2,1 m y tiene cinco grados de libertad."],
	["Data usually reach Earth through Mars orbiters over a UHF link that can reach about 2 Mbps.", "Los datos suelen llegar a la Tierra a través de orbitadores marcianos, con un enlace UHF de hasta unos 2 Mbps."],
	["The rover carries 43 tubes: 38 for samples and 5 witness tubes that record possible contamination.", "El rover lleva 43 tubos: 38 para muestras y 5 tubos testigo que registran posible contaminación."],
	["NASA has not confirmed life on Mars. Habitability, potential biosignatures and confirmed evidence are different things.", "La NASA no ha confirmado vida en Marte. Habitabilidad, posibles biofirmas y evidencia confirmada son cosas distintas."]
]

const REAL_SAMPLES := [
	{"name": "Montdenier", "rock": "Rochette", "kind": ["Igneous rock", "Roca ígnea"], "number": 2, "sol": 194, "date": "2021-09-06"},
	{"name": "Hazeltop", "rock": "Wildcat Ridge", "kind": ["Sedimentary rock", "Roca sedimentaria"], "number": 12, "sol": 509, "date": "2022-07-27"},
	{"name": "Sapphire Canyon", "rock": "Cheyava Falls", "kind": ["Sedimentary rock", "Roca sedimentaria"], "number": 25, "sol": 1215, "date": "2024-07-21"},
	{"name": "Green Gardens", "rock": "Tablelands", "kind": ["Serpentinite", "Serpentinita"], "number": 27, "sol": 1433, "date": "2025-03-02"}
]

const SOURCES := [
	["Mars 2020 Perseverance · Science Objectives", "https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/"],
	["Mars 2020 Perseverance · Science Instruments", "https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/"],
	["Mars 2020 Perseverance · Rover Components", "https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/"],
	["Mars 2020 Perseverance · Mars Rock Samples", "https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/"]
]

static func default_build() -> Dictionary:
	return {"power": "solar", "battery": "small", "wheels": "standard", "comms": "uhf", "computer": "standard", "instruments": ["mastcam", "supercam"]}

static func instrument_name(id: String) -> String:
	var value = INSTRUMENTS[id].name
	return Game.tt(value) if value is Array else String(value)

static func mass(build: Dictionary) -> int:
	var total := 0
	for slot in PART_ORDER: total += int(PARTS[slot].options[String(build.get(slot, ""))].mass)
	for id in build.get("instruments", []): total += int(INSTRUMENTS[id].mass)
	return total

static func cost(build: Dictionary) -> int:
	var total := 0
	for slot in PART_ORDER: total += int(PARTS[slot].options[String(build.get(slot, ""))].cost)
	for id in build.get("instruments", []): total += int(INSTRUMENTS[id].cost)
	return total

## Capacidades del rover derivadas del diseño (modelo educativo).
static func stats(build: Dictionary) -> Dictionary:
	var total_mass := mass(build)
	var wheels := String(build.get("wheels", "standard"))
	var speed: float = {"standard": 150.0, "rugged": 128.0, "light": 182.0}[wheels]
	return {
		"mass": total_mass,
		"speed": speed * (1.12 - total_mass / 260.0),
		"wear": {"standard": 1.0, "rugged": 0.3, "light": 2.0}[wheels],
		"battery": 170.0 if String(build.get("battery", "small")) == "large" else 100.0,
		"solar": String(build.get("power", "solar")) == "solar",
		"memory": 160.0 if String(build.get("computer", "standard")) == "expanded" else 70.0,
		"direct": String(build.get("comms", "uhf")) == "hga",
		"drive_cost": 1.5 * (0.6 + total_mass / 100.0)
	}

## Qué objetivos de una zona puede cumplir este diseño. Devuelve avisos para la Dra. Owen.
static func readiness(build: Dictionary, zone_id: String) -> Array:
	var has: Array = build.get("instruments", [])
	var notes: Array = []
	for objective in ZONES[zone_id].objectives:
		var ok := true
		var why := ["", ""]
		match String(objective.kind):
			"imaged":
				ok = "mastcam" in has
				why = ["needs Mastcam-Z", "requiere Mastcam-Z"]
			"chem_types", "aqueous":
				ok = "supercam" in has or ("pixl" in has and "arm" in has)
				why = ["needs SuperCam, or PIXL with the arm", "requiere SuperCam, o PIXL con el brazo"]
			"sherloc":
				ok = "sherloc" in has and "arm" in has
				why = ["needs SHERLOC and the robotic arm", "requiere SHERLOC y el brazo robótico"]
			"cache_types":
				ok = "arm" in has
				why = ["needs the robotic arm + drill", "requiere el brazo robótico + taladro"]
			"cache_documented":
				ok = "arm" in has and "mastcam" in has
				why = ["needs Mastcam-Z and the arm", "requiere Mastcam-Z y el brazo"]
			"meda":
				ok = "meda" in has
				why = ["needs MEDA", "requiere MEDA"]
			"moxie":
				ok = "moxie" in has
				why = ["needs MOXIE", "requiere MOXIE"]
			"rimfax":
				ok = "rimfax" in has
				why = ["needs RIMFAX", "requiere RIMFAX"]
		notes.append({"ok": ok, "text": objective.text, "why": why})
	return notes
