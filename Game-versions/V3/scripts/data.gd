class_name Data
## Datos de diseño de 2Mars. Los textos van en pares [inglés, español].
##
## PROCEDENCIA DE LOS VALORES
##  - COMPONENTS: catálogo de 30 componentes del libro de ingeniería del equipo (2MARS.xlsx,
##    hoja Components). Masa (kg), potencia (W), créditos, ciencia, movilidad y fiabilidad son
##    PARÁMETROS DE JUEGO del equipo. "nasa" indica solo que el subsistema se inspira en uno real
##    de Perseverance; no certifica las cifras.
##  - MODEL: valores de balance que el libro no trae (Wh de batería, MB de memoria, tasas de
##    enlace del juego). Son un MODELO EDUCATIVO, no datos de la NASA.
##  - REAL_*: datos reales de Perseverance con su fuente; se muestran aparte.

const ZONE_ORDER := ["geology", "life", "archive", "frontier"]

## Valores de balance propios del juego (no vienen del libro ni de la NASA).
const MODEL := {
	"battery_wh": 500.0,        # batería de serie
	"battery_ext_wh": 600.0,    # lo que añade la Batería extendida
	"memory_mb": 80.0,          # memoria de serie
	"storage_mb": 120.0,        # lo que añade Almacenamiento grande
	"heater_w": 30.0,           # calentadores de noche sin RTG
	"minutes_per_second": 10.0, # 1 s de juego = 10 min de misión
	"pass_rate": 5.5,           # MB por segundo de juego durante un paso de orbitador
	"direct_rate": 1.2,         # MB por segundo de juego con alta ganancia (acelerado, ver biblioteca)
	"tubes": 4
}

## Enlaces reales de Perseverance (NASA): relevo UHF hasta 2 Mbps; directo en banda X 160-3000 bps.
const REAL_LINK := {"uhf_mbps": 2.0, "hga_bps_low": 160.0, "hga_bps_high": 3000.0}

const CATEGORIES := [
	{"id": "structure", "name": ["Structure & Body", "Estructura y cuerpo"], "icon": "structure"},
	{"id": "mobility", "name": ["Mobility", "Movilidad"], "icon": "mobility"},
	{"id": "power", "name": ["Power", "Energía"], "icon": "energy"},
	{"id": "science", "name": ["Science", "Ciencia"], "icon": "science"},
	{"id": "sampling", "name": ["Sampling", "Muestreo"], "icon": "sampling"},
	{"id": "computing", "name": ["Computing", "Computación"], "icon": "data"},
	{"id": "comms", "name": ["Communications", "Comunicaciones"], "icon": "comms"}
]

## Grupos de piezas. kind: one = hay que elegir una · optional = una o ninguna · multi = varias.
const GROUPS := [
	{"id": "chassis", "cat": "structure", "kind": "one", "title": ["Chassis", "Chasis"], "options": ["chassis_light", "chassis_std", "chassis_reinf"]},
	{"id": "deck", "cat": "structure", "kind": "one", "title": ["Equipment deck", "Cubierta de equipos"], "options": ["deck_compact", "deck_ext"]},
	{"id": "wheels", "cat": "mobility", "kind": "one", "title": ["Wheels", "Ruedas"], "options": ["wheels_light", "wheels_std", "wheels_reinf"]},
	{"id": "suspension", "cat": "mobility", "kind": "multi", "title": ["Suspension", "Suspensión"], "options": ["rocker"]},
	{"id": "power", "cat": "power", "kind": "one", "title": ["Power source", "Fuente de energía"], "options": ["solar", "rtg"]},
	{"id": "storage_e", "cat": "power", "kind": "multi", "title": ["Energy storage", "Almacenamiento de energía"], "options": ["battery_ext"]},
	{"id": "instruments", "cat": "science", "kind": "multi", "title": ["Science instruments", "Instrumentos científicos"], "options": ["mastcam", "supercam", "pixl", "sherloc", "rimfax", "meda", "moxie"]},
	{"id": "arm", "cat": "sampling", "kind": "optional", "title": ["Robotic arm", "Brazo robótico"], "options": ["arm_std", "arm_ext"]},
	{"id": "tools", "cat": "sampling", "kind": "multi", "title": ["Sampling tools", "Herramientas de muestreo"], "options": ["drill", "regolith"]},
	{"id": "computer", "cat": "computing", "kind": "one", "title": ["Flight computer", "Computadora de vuelo"], "options": ["cpu_basic", "cpu_adv"]},
	{"id": "avionics", "cat": "computing", "kind": "multi", "title": ["Data & navigation", "Datos y navegación"], "options": ["storage", "navsens", "autonav"]},
	{"id": "comms", "cat": "comms", "kind": "multi", "title": ["Antennas", "Antenas"], "options": ["uhf", "hga"]}
]

## Catálogo de 2MARS.xlsx (hoja Components, 30 filas). Orden de campos igual al libro.
const COMPONENTS := {
	"chassis_light": {"cat": "structure", "name": ["Lightweight Chassis", "Chasis ligero"], "fn": ["Frame", "Bastidor"], "adv": ["Low mass", "Poca masa"], "dis": ["Low durability", "Poca durabilidad"], "mass": 80, "power": 0, "cost": 120, "science": 0, "mobility": 5, "rel": 70, "nasa": true, "ref": "Body"},
	"chassis_std": {"cat": "structure", "name": ["Standard Chassis", "Chasis estándar"], "fn": ["Frame", "Bastidor"], "adv": ["Balanced", "Equilibrado"], "dis": ["Average", "Promedio"], "mass": 120, "power": 0, "cost": 180, "science": 0, "mobility": 10, "rel": 85, "nasa": true, "ref": "Body"},
	"chassis_reinf": {"cat": "structure", "name": ["Reinforced Chassis", "Chasis reforzado"], "fn": ["Frame", "Bastidor"], "adv": ["High durability", "Gran durabilidad"], "dis": ["Heavy", "Pesado"], "mass": 180, "power": 0, "cost": 280, "science": 0, "mobility": 8, "rel": 95, "nasa": true, "ref": "Body"},
	"deck_compact": {"cat": "structure", "name": ["Compact Equipment Deck", "Cubierta compacta"], "fn": ["Payload mounting", "Montaje de carga útil"], "adv": ["Low mass", "Poca masa"], "dis": ["Limited capacity", "Capacidad limitada"], "mass": 20, "power": 0, "cost": 40, "science": 0, "mobility": 0, "rel": 80, "nasa": true, "ref": "Equipment Deck"},
	"deck_ext": {"cat": "structure", "name": ["Extended Equipment Deck", "Cubierta extendida"], "fn": ["Payload mounting", "Montaje de carga útil"], "adv": ["More payloads", "Más cargas útiles"], "dis": ["Higher mass", "Más masa"], "mass": 45, "power": 0, "cost": 90, "science": 0, "mobility": 0, "rel": 85, "nasa": true, "ref": "Equipment Deck"},
	"wheels_light": {"cat": "mobility", "name": ["Lightweight Wheels", "Ruedas ligeras"], "fn": ["Locomotion", "Locomoción"], "adv": ["Fast", "Rápidas"], "dis": ["Less durable", "Menos duraderas"], "mass": 25, "power": 30, "cost": 50, "science": 0, "mobility": 15, "rel": 70, "nasa": true, "ref": "Wheels"},
	"wheels_std": {"cat": "mobility", "name": ["Standard Wheels", "Ruedas estándar"], "fn": ["Locomotion", "Locomoción"], "adv": ["Balanced", "Equilibradas"], "dis": ["Average", "Promedio"], "mass": 40, "power": 40, "cost": 80, "science": 0, "mobility": 20, "rel": 85, "nasa": true, "ref": "Wheels"},
	"wheels_reinf": {"cat": "mobility", "name": ["Reinforced Wheels", "Ruedas reforzadas"], "fn": ["Locomotion", "Locomoción"], "adv": ["Durable", "Duraderas"], "dis": ["Heavy", "Pesadas"], "mass": 60, "power": 50, "cost": 130, "science": 0, "mobility": 25, "rel": 95, "nasa": true, "ref": "Wheels"},
	"rocker": {"cat": "mobility", "name": ["Rocker-Bogie", "Rocker-bogie"], "fn": ["Suspension", "Suspensión"], "adv": ["Excellent terrain", "Excelente en terreno difícil"], "dis": ["Complex", "Compleja"], "mass": 70, "power": 10, "cost": 180, "science": 0, "mobility": 40, "rel": 95, "nasa": true, "ref": "Rocker-Bogie"},
	"solar": {"cat": "power", "name": ["Solar Panels", "Paneles solares"], "fn": ["Power source", "Fuente de energía"], "adv": ["Renewable", "Renovable"], "dis": ["Dust dependent", "Depende del polvo"], "mass": 55, "power": 120, "cost": 200, "science": 0, "mobility": 0, "rel": 75, "nasa": false, "ref": "Gameplay"},
	"rtg": {"cat": "power", "name": ["RTG", "RTG"], "fn": ["Power source", "Fuente de energía"], "adv": ["Continuous power", "Energía continua"], "dis": ["Expensive", "Caro"], "mass": 80, "power": 300, "cost": 500, "science": 0, "mobility": 0, "rel": 98, "nasa": true, "ref": "MMRTG"},
	"battery_ext": {"cat": "power", "name": ["Extended Battery", "Batería extendida"], "fn": ["Storage", "Almacenamiento"], "adv": ["Long endurance", "Gran autonomía"], "dis": ["Heavy", "Pesada"], "mass": 70, "power": 0, "cost": 180, "science": 0, "mobility": 0, "rel": 90, "nasa": false, "ref": "Gameplay"},
	"mastcam": {"cat": "science", "name": ["Mastcam-Z", "Mastcam-Z"], "fn": ["Imaging", "Imágenes"], "adv": ["Navigation support", "Apoyo a la navegación"], "dis": ["Data heavy", "Genera muchos datos"], "mass": 4, "power": 20, "cost": 250, "science": 15, "mobility": 0, "rel": 90, "nasa": true, "ref": "Mastcam-Z"},
	"supercam": {"cat": "science", "name": ["SuperCam", "SuperCam"], "fn": ["Remote analysis", "Análisis remoto"], "adv": ["Distance science", "Ciencia a distancia"], "dis": ["Power use", "Consumo de energía"], "mass": 10, "power": 70, "cost": 350, "science": 30, "mobility": 0, "rel": 85, "nasa": true, "ref": "SuperCam"},
	"pixl": {"cat": "science", "name": ["PIXL", "PIXL"], "fn": ["Elemental analysis", "Análisis elemental"], "adv": ["High detail", "Gran detalle"], "dis": ["Needs arm", "Necesita brazo"], "mass": 8, "power": 40, "cost": 300, "science": 35, "mobility": 0, "rel": 90, "nasa": true, "ref": "PIXL"},
	"sherloc": {"cat": "science", "name": ["SHERLOC", "SHERLOC"], "fn": ["Organic detection", "Detección de orgánicos"], "adv": ["Astrobiology", "Astrobiología"], "dis": ["Needs contact", "Necesita contacto"], "mass": 6, "power": 35, "cost": 320, "science": 40, "mobility": 0, "rel": 88, "nasa": true, "ref": "SHERLOC"},
	"rimfax": {"cat": "science", "name": ["RIMFAX", "RIMFAX"], "fn": ["Radar", "Radar"], "adv": ["Subsurface science", "Ciencia del subsuelo"], "dis": ["Large datasets", "Grandes volúmenes de datos"], "mass": 12, "power": 80, "cost": 400, "science": 45, "mobility": 0, "rel": 85, "nasa": true, "ref": "RIMFAX"},
	"meda": {"cat": "science", "name": ["MEDA", "MEDA"], "fn": ["Weather station", "Estación meteorológica"], "adv": ["Climate science", "Ciencia del clima"], "dis": ["Continuous operation", "Operación continua"], "mass": 5, "power": 15, "cost": 220, "science": 20, "mobility": 0, "rel": 95, "nasa": true, "ref": "MEDA"},
	"moxie": {"cat": "science", "name": ["MOXIE", "MOXIE"], "fn": ["Oxygen generation", "Generación de oxígeno"], "adv": ["ISRU objective", "Objetivo ISRU"], "dis": ["Very high power", "Consumo muy alto"], "mass": 18, "power": 300, "cost": 500, "science": 50, "mobility": 0, "rel": 80, "nasa": true, "ref": "MOXIE"},
	"arm_std": {"cat": "sampling", "name": ["Standard Arm", "Brazo estándar"], "fn": ["Sampling", "Muestreo"], "adv": ["Lightweight", "Ligero"], "dis": ["Short reach", "Poco alcance"], "mass": 35, "power": 20, "cost": 150, "science": 10, "mobility": 0, "rel": 85, "nasa": true, "ref": "Robotic Arm"},
	"arm_ext": {"cat": "sampling", "name": ["Extended Arm", "Brazo extendido"], "fn": ["Sampling", "Muestreo"], "adv": ["Long reach", "Gran alcance"], "dis": ["Heavy", "Pesado"], "mass": 60, "power": 35, "cost": 250, "science": 15, "mobility": 0, "rel": 80, "nasa": false, "ref": "Gameplay"},
	"drill": {"cat": "sampling", "name": ["Core Drill", "Taladro de núcleos"], "fn": ["Sample extraction", "Extracción de muestras"], "adv": ["Rock cores", "Núcleos de roca"], "dis": ["Energy intensive", "Gasta mucha energía"], "mass": 15, "power": 120, "cost": 250, "science": 25, "mobility": 0, "rel": 85, "nasa": true, "ref": "Coring Drill"},
	"regolith": {"cat": "sampling", "name": ["Regolith Collector", "Colector de regolito"], "fn": ["Soil collection", "Recolección de suelo"], "adv": ["Fast", "Rápido"], "dis": ["Lower science value", "Menor valor científico"], "mass": 8, "power": 45, "cost": 120, "science": 15, "mobility": 0, "rel": 85, "nasa": false, "ref": "Gameplay"},
	"cpu_basic": {"cat": "computing", "name": ["Basic Computer", "Computadora básica"], "fn": ["Control", "Control"], "adv": ["Efficient", "Eficiente"], "dis": ["Lower autonomy", "Menos autonomía"], "mass": 8, "power": 30, "cost": 150, "science": 0, "mobility": 0, "rel": 85, "nasa": true, "ref": "RCE"},
	"cpu_adv": {"cat": "computing", "name": ["Advanced Computer", "Computadora avanzada"], "fn": ["Control", "Control"], "adv": ["High autonomy", "Mucha autonomía"], "dis": ["Power draw", "Consume más"], "mass": 15, "power": 65, "cost": 300, "science": 0, "mobility": 0, "rel": 90, "nasa": true, "ref": "RCE"},
	"storage": {"cat": "computing", "name": ["Large Storage", "Almacenamiento grande"], "fn": ["Data storage", "Almacenamiento de datos"], "adv": ["Stores more science", "Guarda más ciencia"], "dis": ["Mass", "Masa"], "mass": 20, "power": 8, "cost": 220, "science": 10, "mobility": 0, "rel": 90, "nasa": false, "ref": "Gameplay"},
	"navsens": {"cat": "computing", "name": ["Advanced Navigation Sensors", "Sensores de navegación avanzados"], "fn": ["Navigation", "Navegación"], "adv": ["Precision", "Precisión"], "dis": ["Cost", "Costo"], "mass": 15, "power": 25, "cost": 180, "science": 0, "mobility": 25, "rel": 92, "nasa": true, "ref": "Navcams/IMU"},
	"autonav": {"cat": "computing", "name": ["Enhanced AutoNav", "AutoNav mejorado"], "fn": ["Autonomy", "Autonomía"], "adv": ["Autonomous driving", "Conducción autónoma"], "dis": ["Processing needs", "Exige procesamiento"], "mass": 10, "power": 50, "cost": 250, "science": 0, "mobility": 30, "rel": 90, "nasa": true, "ref": "AutoNav"},
	"hga": {"cat": "comms", "name": ["High-Gain Antenna", "Antena de alta ganancia"], "fn": ["Communication", "Comunicación"], "adv": ["Fast transmission", "Transmisión rápida"], "dis": ["Needs pointing", "Hay que apuntarla"], "mass": 12, "power": 40, "cost": 180, "science": 0, "mobility": 0, "rel": 88, "nasa": true, "ref": "High-Gain Antenna"},
	"uhf": {"cat": "comms", "name": ["UHF Relay", "Relevo UHF"], "fn": ["Communication", "Comunicación"], "adv": ["High data return", "Gran retorno de datos"], "dis": ["Orbiter dependent", "Depende del orbitador"], "mass": 10, "power": 25, "cost": 150, "science": 0, "mobility": 0, "rel": 90, "nasa": true, "ref": "UHF Relay"}
}

## Qué hace cada pieza EN EL JUEGO (consecuencia operativa real, no solo cifras).
const EFFECTS := {
	"chassis_light": ["Collisions, dust devils and hard landings hurt twice as much.", "Choques, remolinos y aterrizajes duros dañan el doble."],
	"chassis_std": ["Normal damage from collisions and landing.", "Daño normal por choques y aterrizaje."],
	"chassis_reinf": ["Shrugs off most collision and landing damage.", "Resiste casi todo el daño de choques y aterrizaje."],
	"deck_compact": ["Room for 4 payloads (instruments, arm and tools).", "Espacio para 4 cargas útiles (instrumentos, brazo y herramientas)."],
	"deck_ext": ["Room for 8 payloads.", "Espacio para 8 cargas útiles."],
	"wheels_light": ["Fastest. Sharp rocks wear them twice as fast.", "Las más rápidas. Las rocas afiladas las desgastan el doble."],
	"wheels_std": ["Balanced speed and wear.", "Velocidad y desgaste equilibrados."],
	"wheels_reinf": ["Slower, but sharp rocks barely wear them.", "Más lentas, pero las rocas afiladas casi no las desgastan."],
	"rocker": ["Keeps speed on slopes and soft sand.", "Mantiene la velocidad en pendientes y arena blanda."],
	"solar": ["120 W in full sun, nothing at night; dust and storms cut output. Heaters must run at night.", "120 W a pleno sol y nada de noche; el polvo y las tormentas la reducen. De noche hay que encender calentadores."],
	"rtg": ["300 W day and night (game value; Perseverance's real MMRTG gives about 110 W). Its heat keeps the rover warm.", "300 W de día y de noche (valor de juego; el MMRTG real de Perseverance da unos 110 W). Su calor mantiene tibio al rover."],
	"battery_ext": ["+600 Wh of stored energy (game model) for nights and demanding instruments.", "+600 Wh de energía almacenada (modelo de juego) para noches e instrumentos exigentes."],
	"mastcam": ["Context photos from up to 3 angles; documents a site before sampling.", "Fotos de contexto desde hasta 3 ángulos; documenta el sitio antes de muestrear."],
	"supercam": ["Reads rock composition from a distance.", "Lee la composición de la roca a distancia."],
	"pixl": ["Contact chemistry map. Mounted on the arm.", "Mapa químico por contacto. Va montado en el brazo."],
	"sherloc": ["Contact search for organics and minerals. Mounted on the arm.", "Búsqueda por contacto de orgánicos y minerales. Va montado en el brazo."],
	"rimfax": ["Scans buried layers at radar sites.", "Escanea capas enterradas en los sitios de radar."],
	"meda": ["Logs weather and warns of storms and dust devils.", "Registra el clima y avisa de tormentas y remolinos."],
	"moxie": ["One-hour oxygen run that draws 300 W.", "Prueba de oxígeno de una hora que consume 300 W."],
	"arm_std": ["Carries PIXL, SHERLOC and the drill. You must park right next to the rock.", "Lleva PIXL, SHERLOC y el taladro. Hay que estacionarse pegado a la roca."],
	"arm_ext": ["Same tools, but reaches rocks from farther away.", "Las mismas herramientas, pero alcanza rocas desde más lejos."],
	"drill": ["Cores rock and seals it in a tube. Mounted on the arm.", "Extrae núcleos de roca y los sella en un tubo. Va montado en el brazo."],
	"regolith": ["Scoops loose soil quickly; also saves a sample when a rock crumbles.", "Recoge suelo suelto con rapidez; también rescata una muestra cuando una roca se desmorona."],
	"cpu_basic": ["Low power draw. Cannot run AutoNav.", "Bajo consumo. No puede ejecutar AutoNav."],
	"cpu_adv": ["Runs AutoNav and compresses science data by 20%.", "Ejecuta AutoNav y comprime los datos científicos un 20%."],
	"storage": ["+120 MB of memory (game model) between transmissions.", "+120 MB de memoria (modelo de juego) entre transmisiones."],
	"navsens": ["Lands closer to the science and softens collisions.", "Aterriza más cerca de la ciencia y suaviza los choques."],
	"autonav": ["Press G: the rover drives itself to the next target.", "Pulsa G: el rover conduce solo hasta el siguiente objetivo."],
	"hga": ["Direct link to Earth at any time, slower than the relay.", "Enlace directo con la Tierra en cualquier momento, más lento que el relevo."],
	"uhf": ["Fast relay, only while an orbiter passes overhead.", "Relevo rápido, solo mientras pasa un orbitador."]
}

## Actividad de cada instrumento en operaciones. hours = duración de misión; la energía sale de
## potencia (W del libro) x horas. mb y range son modelo de juego.
const INSTRUMENTS := {
	"mastcam": {"hours": 0.5, "mb": 8, "range": 250, "arm": false, "mode": "focus",
		"real": ["Zoomable stereo cameras on the mast that image the terrain.", "Cámaras estéreo con zoom en el mástil que fotografían el terreno."],
		"game": ["Context image from a distance. Tells igneous from sedimentary rock and documents a site before sampling.", "Imagen de contexto a distancia. Distingue roca ígnea de sedimentaria y documenta el sitio antes de tomar una muestra."],
		"mini": ["Focusing the zoom lenses: a sharp image shows grain and layering.", "Enfoque de las lentes con zoom: una imagen nítida muestra granos y capas."]},
	"supercam": {"hours": 0.5, "mb": 10, "range": 190, "arm": false, "mode": "timing",
		"real": ["Uses a laser and spectrometers to study rock composition from a distance.", "Usa un láser y espectrómetros para estudiar la composición de las rocas a distancia."],
		"game": ["Remote composition. Reveals the minerals in a rock without touching it.", "Composición a distancia. Revela los minerales de una roca sin tocarla."],
		"mini": ["Three laser shots: each one must hit the same small spot to read its light.", "Tres disparos de láser: cada uno debe dar en el mismo punto para leer su luz."]},
	"pixl": {"hours": 2.0, "mb": 20, "range": 70, "arm": true, "mode": "steady",
		"real": ["X-ray instrument on the arm that maps the elemental chemistry of rocks.", "Instrumento de rayos X en el brazo que mapea la química elemental de las rocas."],
		"game": ["Contact chemistry. The most detailed geology data.", "Química por contacto. Los datos de geología más detallados."],
		"mini": ["Holding the sensor steady, millimetres from the rock, while it scans.", "Mantener el sensor estable, a milímetros de la roca, mientras escanea."]},
	"sherloc": {"hours": 2.0, "mb": 24, "range": 70, "arm": true, "mode": "steady",
		"real": ["Arm instrument that searches for organic molecules and minerals; WATSON is its camera.", "Instrumento del brazo que busca moléculas orgánicas y minerales; WATSON es su cámara."],
		"game": ["Contact search for organics. Key to astrobiology.", "Búsqueda de orgánicos por contacto. Clave para la astrobiología."],
		"mini": ["Holding the sensor steady while its laser scans the surface.", "Mantener el sensor estable mientras su láser recorre la superficie."]},
	"rimfax": {"hours": 1.0, "mb": 18, "range": 0, "arm": false, "mode": "timing",
		"real": ["Ground-penetrating radar that images layers beneath the surface.", "Radar de penetración terrestre que muestra capas bajo la superficie."],
		"game": ["Scan buried layers at radar sites (R on a site).", "Escanea capas enterradas en los sitios de radar (R sobre un sitio)."],
		"mini": ["Radar pulses: catch each echo as it returns from the buried layers.", "Pulsos de radar: capta cada eco cuando vuelve de las capas enterradas."]},
	"meda": {"hours": 0.0, "mb": 4, "range": 0, "arm": false, "mode": "",
		"real": ["Weather station: wind, temperature, pressure, humidity and dust.", "Estación meteorológica: viento, temperatura, presión, humedad y polvo."],
		"game": ["Logs weather while switched on (M) and warns before storms and dust devils.", "Registra el clima mientras está encendido (M) y avisa antes de tormentas y remolinos."],
		"mini": ["", ""]},
	"moxie": {"hours": 1.0, "mb": 16, "range": 0, "arm": false, "mode": "",
		"real": ["Technology demonstration that made oxygen from Mars' CO2 atmosphere. Not a life-support system.", "Demostración tecnológica que produjo oxígeno a partir del CO2 de Marte. No es un sistema de soporte vital."],
		"game": ["Run an oxygen experiment (O). Heavy and power-hungry.", "Ejecuta un experimento de oxígeno (O). Pesado y consume mucha energía."],
		"mini": ["", ""]},
	"drill": {"hours": 1.0, "mb": 6, "range": 70, "arm": true, "mode": "steady",
		"real": ["A coring drill on the arm; cores are sealed in sample tubes.", "Un taladro de núcleos en el brazo; los núcleos se sellan en tubos de muestra."],
		"game": ["Cores and caches up to 4 samples.", "Extrae y guarda hasta 4 muestras."],
		"mini": ["Keeping steady pressure on the drill so the core comes out whole.", "Mantener presión constante en el taladro para que el núcleo salga entero."]},
	"regolith": {"hours": 0.5, "mb": 4, "range": 70, "arm": false, "mode": "focus",
		"real": ["Perseverance collected regolith with a special bit; this collector is a game simplification.", "Perseverance recolectó regolito con una broca especial; este colector es una simplificación del juego."],
		"game": ["Scoops loose soil into a tube.", "Recoge suelo suelto en un tubo."],
		"mini": ["Lowering the scoop to the right depth.", "Bajar la pala a la profundidad correcta."]}
}
const INSTRUMENT_ORDER := ["mastcam", "supercam", "pixl", "sherloc", "rimfax", "meda", "moxie"]
const ROCK_ACTIONS := ["mastcam", "supercam", "pixl", "sherloc", "drill", "regolith"]

## Rocas ficticias del juego, inspiradas en unidades de Jezero. "analog" apunta a una muestra REAL
## de Perseverance del mismo tipo general (solo como referencia; no es la roca del jugador).
const ROCKS := {
	"basalt": {"name": ["Basaltic rock", "Roca basáltica"], "klass": "igneous", "color": "#6f5a57", "aqueous": false, "organics": false, "fragile": false, "analog": 0,
		"chem": ["Pyroxene and plagioclase: cooled lava.", "Piroxeno y plagioclasa: lava enfriada."]},
	"olivine": {"name": ["Olivine-rich rock", "Roca rica en olivino"], "klass": "igneous", "color": "#7d8a4f", "aqueous": false, "organics": false, "fragile": false, "analog": 0,
		"chem": ["Coarse olivine crystals that settled in a thick body of magma.", "Cristales gruesos de olivino que se asentaron en un cuerpo de magma."]},
	"mudstone": {"name": ["Delta mudstone", "Lutita del delta"], "klass": "sedimentary", "color": "#b58a6a", "aqueous": true, "organics": true, "fragile": true, "analog": 1,
		"chem": ["Fine clay-rich layers that settled in calm lake water.", "Capas finas ricas en arcilla que se depositaron en aguas tranquilas de lago."]},
	"sandstone": {"name": ["Delta sandstone", "Arenisca del delta"], "klass": "sedimentary", "color": "#c99a62", "aqueous": true, "organics": false, "fragile": false, "analog": 1,
		"chem": ["Sand grains carried and rounded by a river.", "Granos de arena transportados y redondeados por un río."]},
	"carbonate": {"name": ["Carbonate-bearing rock", "Roca con carbonatos"], "klass": "sedimentary", "color": "#d8c9a3", "aqueous": true, "organics": true, "fragile": false, "analog": 2,
		"chem": ["Carbonate minerals that form in water that is not too acidic.", "Minerales de carbonato que se forman en agua no demasiado ácida."]},
	"sulfate": {"name": ["Sulfate-bearing rock", "Roca con sulfatos"], "klass": "sedimentary", "color": "#e3d7c5", "aqueous": true, "organics": false, "fragile": true, "analog": 1,
		"chem": ["Sulfate salts left behind as salty water evaporated.", "Sales de sulfato que quedaron al evaporarse agua salada."]},
	"silica": {"name": ["Hydrated silica", "Sílice hidratada"], "klass": "sedimentary", "color": "#cfd9d6", "aqueous": true, "organics": true, "fragile": false, "analog": 2,
		"chem": ["Water-bearing silica, a material that preserves delicate traces well.", "Sílice con agua, un material que conserva bien rastros delicados."]},
	"regolith": {"name": ["Regolith patch", "Parche de regolito"], "klass": "soil", "color": "#b5674a", "aqueous": false, "organics": false, "fragile": true, "analog": -1,
		"chem": ["Loose dust and broken rock: what wheels, suits and habitats must deal with.", "Polvo suelto y roca triturada: con lo que lidian ruedas, trajes y hábitats."]}
}

## Preguntas de interpretación. Estructura: evidencia observada -> término explicado -> una
## pregunta clara -> por qué acierta la correcta y por qué falla cada error.
const QUIZ := {
	"igneous": {
		"see": ["The instrument found minerals that crystallise from molten rock.", "El instrumento encontró minerales que cristalizan a partir de roca fundida."],
		"term": ["Igneous rock = rock that was once lava or magma and then cooled.", "Roca ígnea = roca que fue lava o magma y luego se enfrió."],
		"q": ["What is this rock most useful for?", "¿Para qué sirve más esta roca?"],
		"options": [["Proving that life existed here", "Demostrar que aquí hubo vida"], ["Dating: it works like a clock for the crater's history", "Fechar: funciona como un reloj para la historia del cráter"], ["Showing that water never existed here", "Mostrar que aquí nunca hubo agua"]], "correct": 1,
		"why": ["Lava rocks record when they cooled, so in a laboratory they can be dated. That gives the region's history a clock.", "Las rocas de lava registran cuándo se enfriaron, así que en un laboratorio se pueden fechar. Eso le da un reloj a la historia de la región."],
		"wrong": [["A lava rock says nothing about life.", "Una roca de lava no dice nada sobre la vida."], ["", ""], ["One dry rock cannot rule out water elsewhere or at another time.", "Una roca seca no descarta agua en otro lugar o en otra época."]]},
	"water": {
		"see": ["The instrument found minerals that only form in liquid water.", "El instrumento encontró minerales que solo se forman en agua líquida."],
		"term": ["Habitable = a place that had the conditions life needs. It does not mean something lived there.", "Habitable = un lugar que tuvo las condiciones que la vida necesita. No significa que algo viviera allí."],
		"q": ["What can you report from this evidence?", "¿Qué puedes informar con esta evidencia?"],
		"options": [["This place was once habitable", "Este lugar fue habitable alguna vez"], ["Life existed here", "Aquí existió vida"], ["Nothing useful", "Nada útil"]], "correct": 0,
		"why": ["Water-formed minerals show the right conditions existed. That is habitability, a real and useful result.", "Los minerales formados en agua muestran que existieron las condiciones adecuadas. Eso es habitabilidad, un resultado real y útil."],
		"wrong": [["", ""], ["Water is a condition for life, not evidence of life.", "El agua es una condición para la vida, no una evidencia de vida."], ["It tells us where to look next: that is useful.", "Indica dónde buscar después: eso es útil."]]},
	"organics": {
		"see": ["SHERLOC detected organic molecules next to water-formed minerals.", "SHERLOC detectó moléculas orgánicas junto a minerales formados en agua."],
		"term": ["Organic molecules = carbon-based molecules. Living things make them, but so do volcanoes, meteorites and chemistry in water. Biosignature = a sign that MIGHT come from life.", "Moléculas orgánicas = moléculas basadas en carbono. Los seres vivos las producen, pero también los volcanes, los meteoritos y la química en agua. Biofirma = una señal que PODRÍA venir de la vida."],
		"q": ["How should this result be reported?", "¿Cómo debe informarse este resultado?"],
		"options": [["Confirmed: ancient life on Mars", "Confirmado: vida antigua en Marte"], ["A potential biosignature worth caching for labs on Earth", "Una posible biofirma que conviene guardar para laboratorios en la Tierra"], ["Contamination: ignore it", "Contaminación: ignóralo"]], "correct": 1,
		"why": ["Organics can form without biology. NASA has not confirmed life on Mars; a strong claim needs laboratory study, so the right step is to keep the sample.", "Los orgánicos pueden formarse sin biología. La NASA no ha confirmado vida en Marte; una afirmación fuerte exige estudio en laboratorio, así que lo correcto es conservar la muestra."],
		"wrong": [["An instrument that finds organics has not found life.", "Un instrumento que encuentra orgánicos no ha encontrado vida."], ["", ""], ["There is no evidence of contamination; discarding it would waste a real lead.", "No hay evidencia de contaminación; descartarlo desperdiciaría una pista real."]]},
	"cache": {
		"see": ["A rock core is now sealed in a tube.", "Un núcleo de roca queda sellado en un tubo."],
		"term": ["Context = where the sample came from: the site, the rock type and its surroundings.", "Contexto = de dónde salió la muestra: el sitio, el tipo de roca y su entorno."],
		"q": ["Why photograph and record the site before sealing a sample?", "¿Por qué fotografiar y registrar el sitio antes de sellar una muestra?"],
		"options": [["Its origin tells scientists how to read it", "Su origen les dice a los científicos cómo interpretarla"], ["To make the tube lighter", "Para que el tubo pese menos"], ["Only for publicity photos", "Solo para fotos de prensa"]], "correct": 0,
		"why": ["Without context a sample is just a rock. Each one is documented with its location, rock type and surroundings.", "Sin contexto una muestra es solo una roca. Cada una se documenta con su ubicación, tipo de roca y entorno."],
		"wrong": [["", ""], ["A photo does not change the tube's mass.", "Una foto no cambia la masa del tubo."], ["The images are science data used to interpret the sample.", "Las imágenes son datos científicos para interpretar la muestra."]]},
	"radar": {
		"see": ["The radar image shows tilted bands below the surface.", "La imagen del radar muestra bandas inclinadas bajo la superficie."],
		"term": ["Strata = layers of rock laid down one after another over time.", "Estratos = capas de roca depositadas una tras otra con el tiempo."],
		"q": ["What are those bands?", "¿Qué son esas bandas?"],
		"options": [["Buried strata that record how the terrain was built", "Estratos enterrados que registran cómo se formó el terreno"], ["Underground cities", "Ciudades subterráneas"], ["Radio noise with no meaning", "Ruido de radio sin significado"]], "correct": 0,
		"why": ["Ground-penetrating radar reads the geology you cannot see from the surface.", "El radar de penetración lee la geología que no se ve desde la superficie."],
		"wrong": [["", ""], ["Nothing in the data suggests built structures.", "Nada en los datos sugiere estructuras construidas."], ["Noise is random; these bands are continuous and ordered.", "El ruido es aleatorio; estas bandas son continuas y ordenadas."]]},
	"moxie": {
		"see": ["The experiment made a small amount of oxygen from Mars' CO2 air.", "El experimento produjo un poco de oxígeno a partir del aire de CO2 de Marte."],
		"term": ["Technology demonstration = a small test that shows a method works. ISRU = using local resources instead of bringing everything from Earth.", "Demostración tecnológica = una prueba pequeña que muestra que un método funciona. ISRU = usar recursos del lugar en vez de traerlo todo desde la Tierra."],
		"q": ["What does this result mean?", "¿Qué significa este resultado?"],
		"options": [["Astronauts can already live on Mars", "Los astronautas ya pueden vivir en Marte"], ["Future missions could make oxygen in place", "Misiones futuras podrían producir oxígeno en el lugar"], ["Mars air is breathable", "El aire de Marte es respirable"]], "correct": 1,
		"why": ["MOXIE proved the method at small scale. It is not a life-support system.", "MOXIE probó el método a pequeña escala. No es un sistema de soporte vital."],
		"wrong": [["A small test is far from a full life-support system.", "Una prueba pequeña está lejos de un sistema de soporte vital."], ["", ""], ["The air is still mostly CO2; the oxygen came from the machine.", "El aire sigue siendo casi todo CO2; el oxígeno lo produjo la máquina."]]},
	"weather": {
		"see": ["MEDA logged wind, temperature, pressure and dust.", "MEDA registró viento, temperatura, presión y polvo."],
		"term": ["Mars has no rain, but it has dust storms and big temperature swings.", "En Marte no llueve, pero hay tormentas de polvo y grandes cambios de temperatura."],
		"q": ["Why log the weather every day?", "¿Por qué registrar el clima todos los días?"],
		"options": [["The records help design safe future missions", "Los registros ayudan a diseñar misiones futuras seguras"], ["To predict rain", "Para predecir la lluvia"], ["Weather does not matter on Mars", "El clima no importa en Marte"]], "correct": 0,
		"why": ["Dust affects power, machines and people. Knowing the environment comes first.", "El polvo afecta la energía, las máquinas y a las personas. Conocer el entorno es lo primero."],
		"wrong": [["", ""], ["It does not rain on Mars today.", "Hoy no llueve en Marte."], ["Dust storms can cut solar power for weeks.", "Las tormentas de polvo pueden cortar la energía solar durante semanas."]]}
}

const ZONES := {
	"geology": {"name": ["Crater Floor", "Suelo del cráter"], "goal": ["Geology", "Geología"], "color": "#FFAD45", "ground": "#c66a47", "time": 300, "hazards": ["sharp"], "need_mb": 45, "lat": 18.43, "lon": 77.45,
		"nasa": ["Science objective: study the rocks and landscape to reveal the region's history.", "Objetivo científico: estudiar las rocas y el paisaje para revelar la historia de la región."],
		"brief": ["Lava rocks on the crater floor hold the oldest pages of this story. Document the rocks and find out what they are made of.", "Las rocas de lava del suelo del cráter guardan las páginas más antiguas de esta historia. Documenta las rocas y averigua de qué están hechas."],
		"rocks": {"basalt": 3, "olivine": 2, "regolith": 1}, "sites": 0, "suggest": ["mastcam", "supercam"],
		"objectives": [{"kind": "imaged", "need": 3, "text": ["Photograph 3 rocks for context", "Fotografía 3 rocas para tener contexto"]}, {"kind": "chem_types", "need": 2, "text": ["Get the composition of 2 different rock types", "Obtén la composición de 2 tipos de roca distintos"]}, {"kind": "received", "need": 45, "text": ["Receive 45 MB of science on Earth", "Recibe 45 MB de ciencia en la Tierra"]},
			{"kind": "angles", "need": 1, "opt": true, "text": ["Photograph one rock from 3 angles", "Fotografía una roca desde 3 ángulos"]}, {"kind": "pixl", "need": 1, "opt": true, "text": ["Map one rock's chemistry with PIXL", "Mapea la química de una roca con PIXL"]}]},
	"life": {"name": ["Ancient Delta", "Delta antiguo"], "goal": ["Search for Life", "Búsqueda de vida"], "color": "#91C6BB", "ground": "#c98a5c", "time": 330, "hazards": ["devils", "sand", "slope"], "need_mb": 70, "lat": 18.52, "lon": 77.38,
		"nasa": ["Science objective: look for environments that were habitable and for signs of ancient microbial life.", "Objetivo científico: buscar ambientes que fueron habitables y señales de vida microbiana antigua."],
		"brief": ["A river once fed a lake here. Fine sediments are the best place to preserve traces. Find water-formed rocks and search them for organics.", "Un río alimentó un lago aquí. Los sedimentos finos son el mejor lugar para conservar rastros. Encuentra rocas formadas en agua y busca orgánicos en ellas."],
		"rocks": {"mudstone": 3, "sandstone": 2, "carbonate": 1, "basalt": 1}, "sites": 0, "suggest": ["supercam", "arm_std", "sherloc"],
		"objectives": [{"kind": "aqueous", "need": 2, "text": ["Identify 2 rocks that formed in water", "Identifica 2 rocas formadas en agua"]}, {"kind": "sherloc", "need": 2, "text": ["Search 2 rocks for organics with SHERLOC", "Busca orgánicos en 2 rocas con SHERLOC"]}, {"kind": "quiz", "need": 2, "text": ["Report 2 findings at the right level of certainty", "Informa 2 hallazgos con el nivel de certeza correcto"]}, {"kind": "received", "need": 70, "text": ["Receive 70 MB of science on Earth", "Recibe 70 MB de ciencia en la Tierra"]},
			{"kind": "imaged", "need": 2, "opt": true, "text": ["Photograph 2 rocks for context", "Fotografía 2 rocas para tener contexto"]}, {"kind": "cache_types", "need": 1, "opt": true, "text": ["Cache one sample for a future lab", "Guarda una muestra para un futuro laboratorio"]}]},
	"archive": {"name": ["Delta Margin", "Margen del delta"], "goal": ["Sample Archive", "Archivo de muestras"], "color": "#F5DB98", "ground": "#b9774f", "time": 360, "hazards": ["storm", "sharp", "devils", "slope"], "need_mb": 40, "lat": 18.47, "lon": 77.3,
		"nasa": ["Science objective: collect and document rock and regolith samples for possible return to Earth.", "Objetivo científico: recolectar y documentar muestras de roca y regolito para su posible retorno a la Tierra."],
		"brief": ["You carry only four tubes. Choose samples that tell different stories, and document every site before you drill.", "Solo llevas cuatro tubos. Elige muestras que cuenten historias distintas y documenta cada sitio antes de perforar."],
		"rocks": {"carbonate": 2, "sulfate": 1, "silica": 1, "mudstone": 1, "olivine": 1, "basalt": 1}, "sites": 0, "suggest": ["mastcam", "arm_std", "drill"],
		"objectives": [{"kind": "cache_types", "need": 3, "text": ["Cache 3 samples of different rock types", "Guarda 3 muestras de tipos de roca distintos"]}, {"kind": "cache_documented", "need": 3, "text": ["Photograph each site before coring (3)", "Fotografía cada sitio antes de perforar (3)"]}, {"kind": "received", "need": 40, "text": ["Receive 40 MB of sample records on Earth", "Recibe 40 MB de registros de muestras en la Tierra"]},
			{"kind": "chem_types", "need": 2, "opt": true, "text": ["Get the composition of 2 rock types", "Obtén la composición de 2 tipos de roca"]}, {"kind": "angles", "need": 2, "opt": true, "text": ["Photograph 2 rocks from 3 angles", "Fotografía 2 rocas desde 3 ángulos"]}]},
	"frontier": {"name": ["Landing Plains", "Llanura de aterrizaje"], "goal": ["Human Frontier", "Frontera humana"], "color": "#AA5D40", "ground": "#b9694a", "time": 360, "hazards": ["cold", "storm", "devils"], "need_mb": 55, "lat": 18.36, "lon": 77.6,
		"nasa": ["Science objective: prepare for human exploration by studying the environment and testing technology.", "Objetivo científico: preparar la exploración humana estudiando el ambiente y probando tecnología."],
		"brief": ["Before people arrive we must know the weather, the dust, the ground and whether oxygen can be made here.", "Antes de que llegue la gente hay que conocer el clima, el polvo, el suelo y si aquí se puede producir oxígeno."],
		"rocks": {"regolith": 3, "basalt": 2}, "sites": 2, "suggest": ["meda", "moxie", "rimfax"],
		"objectives": [{"kind": "meda", "need": 4, "text": ["Log 4 weather reports with MEDA", "Registra 4 informes meteorológicos con MEDA"]}, {"kind": "moxie", "need": 1, "text": ["Complete one MOXIE oxygen run", "Completa una prueba de oxígeno con MOXIE"]}, {"kind": "rimfax", "need": 1, "text": ["Scan one buried site with RIMFAX", "Escanea un sitio enterrado con RIMFAX"]}, {"kind": "received", "need": 55, "text": ["Receive 55 MB of science on Earth", "Recibe 55 MB de ciencia en la Tierra"]},
			{"kind": "regolith", "need": 1, "opt": true, "text": ["Collect one regolith sample", "Recoge una muestra de regolito"]}, {"kind": "rimfax", "need": 2, "opt": true, "text": ["Scan both radar sites", "Escanea los dos sitios de radar"]}]}
}

## Opciones de planificación de misión (modelo de juego; los hechos reales van en "real").
const PROFILES := {
	"scout": {"name": ["Focused scout", "Explorador ligero"], "mass": 380, "budget": 2400, "time": 0.85, "data": 0.85,
		"note": ["A small launcher and a tight budget. Fewer instruments, clearer choices.", "Un lanzador pequeño y un presupuesto ajustado. Menos instrumentos, decisiones más claras."]},
	"explorer": {"name": ["Balanced explorer", "Explorador equilibrado"], "mass": 460, "budget": 3200, "time": 1.0, "data": 1.0,
		"note": ["The reference mission: room for a solid science payload if you choose well.", "La misión de referencia: espacio para una buena carga científica si eliges bien."]},
	"flagship": {"name": ["Flagship laboratory", "Laboratorio insignia"], "mass": 560, "budget": 4200, "time": 1.0, "data": 1.25,
		"note": ["A heavy launcher and a big budget, but Earth expects 25% more data.", "Un lanzador pesado y un gran presupuesto, pero la Tierra espera un 25% más de datos."]}
}
const PROFILE_ORDER := ["scout", "explorer", "flagship"]
const WINDOWS := {
	"early": {"name": ["Early window", "Ventana temprana"], "budget": -200, "time": 1.15, "storm": 1.25,
		"note": ["Less time to prepare (−200 cr), but you arrive well before the dust season: more surface time.", "Menos tiempo de preparación (−200 cr), pero llegas mucho antes de la temporada de polvo: más tiempo en superficie."]},
	"optimal": {"name": ["Optimal window", "Ventana óptima"], "budget": 0, "time": 1.0, "storm": 1.0,
		"note": ["The planned window. No bonus, no penalty.", "La ventana planificada. Sin ventaja ni penalización."]},
	"late": {"name": ["Late window", "Ventana tardía"], "budget": 250, "time": 0.85, "storm": 0.7,
		"note": ["More time to build (+250 cr), but you land closer to the dust season: less surface time.", "Más tiempo para construir (+250 cr), pero aterrizas más cerca de la temporada de polvo: menos tiempo en superficie."]}
}
const WINDOW_ORDER := ["early", "optimal", "late"]
const SITES := {
	"flat": {"name": ["Open plain", "Llanura abierta"], "stress": 0.0, "near": 0.0,
		"note": ["Smooth ground: a gentle landing, but a longer drive to the science.", "Suelo liso: un aterrizaje suave, pero un trayecto más largo hasta la ciencia."]},
	"rough": {"name": ["Near the outcrops", "Junto a los afloramientos"], "stress": 1.0, "near": 1.0,
		"note": ["You land beside the rocks you came to study, on rougher ground. A weak chassis will feel it.", "Aterrizas junto a las rocas que viniste a estudiar, en suelo más áspero. Un chasis débil lo notará."]}
}
const SITE_ORDER := ["flat", "rough"]
const PRIORITIES := {
	"context": {"name": ["Images & context", "Imágenes y contexto"], "kinds": ["mastcam"], "note": ["Context images count 30% more.", "Las imágenes de contexto valen un 30% más."]},
	"composition": {"name": ["Composition", "Composición"], "kinds": ["supercam", "pixl", "sherloc"], "note": ["Composition analyses count 30% more.", "Los análisis de composición valen un 30% más."]},
	"samples": {"name": ["Samples", "Muestras"], "kinds": ["drill", "regolith"], "note": ["Sample records count 30% more.", "Los registros de muestras valen un 30% más."]},
	"environment": {"name": ["Environment", "Ambiente"], "kinds": ["meda", "moxie", "rimfax"], "note": ["Weather, radar and oxygen data count 30% more.", "Los datos de clima, radar y oxígeno valen un 30% más."]}
}
const PRIORITY_ORDER := ["context", "composition", "samples", "environment"]

## Los seis factores conectados que presenta la Dra. Owen.
const FACTORS := [
	{"id": "time", "name": ["Time", "Tiempo"], "note": ["Launch windows and mission days are limited.", "Las ventanas de lanzamiento y los días de misión son limitados."]},
	{"id": "data", "name": ["Data", "Datos"], "note": ["Every photo and analysis must be stored and sent.", "Cada foto y análisis hay que guardarlo y enviarlo."]},
	{"id": "budget", "name": ["Budget", "Presupuesto"], "note": ["Credits pay for every component.", "Los créditos pagan cada componente."]},
	{"id": "mass", "name": ["Mass", "Masa"], "note": ["The launcher can only lift so much.", "El lanzador solo puede levantar cierta masa."]},
	{"id": "energy", "name": ["Energy", "Energía"], "note": ["Driving, science and radio all draw power.", "Conducir, hacer ciencia y transmitir gastan energía."]},
	{"id": "comms", "name": ["Communications", "Comunicaciones"], "note": ["Science only counts when Earth receives it.", "La ciencia solo cuenta cuando la Tierra la recibe."]}
]

## Conversaciones opcionales («¡Espera! ¿No tienes algo más que contarme?»). Hechos reales.
const STORIES := {
	"wheels": {"title": ["Curiosity's wheels", "Las ruedas de Curiosity"], "source": "NASA/JPL · Curiosity & Mars 2020 rover wheels",
		"text": ["Curiosity's aluminium wheels picked up holes and tears from sharp rocks sooner than expected. The team changed its routes and its driving software. Perseverance's wheels were redesigned: thicker skin and 48 gently curved treads instead of 24 chevrons.", "Las ruedas de aluminio de Curiosity sufrieron agujeros y desgarros por rocas afiladas antes de lo previsto. El equipo cambió sus rutas y su software de conducción. Las ruedas de Perseverance se rediseñaron: piel más gruesa y 48 relieves suavemente curvos en lugar de 24 en forma de V."]},
	"spirit": {"title": ["Spirit and the sand trap", "Spirit y la trampa de arena"], "source": "NASA/JPL · Mars Exploration Rover Spirit",
		"text": ["In 2009 the rover Spirit broke through a crust into soft soil and could not drive out. It kept working as a fixed science station until contact was lost in 2010. Soft ground is a real mobility risk.", "En 2009 el rover Spirit rompió una costra y quedó atrapado en suelo blando. Siguió trabajando como estación científica fija hasta que se perdió el contacto en 2010. El suelo blando es un riesgo real de movilidad."]},
	"dust": {"title": ["Opportunity and the dust", "Opportunity y el polvo"], "source": "NASA/JPL · Mars Exploration Rover Opportunity",
		"text": ["Opportunity was planned for 90 days and worked for more than 14 years: wind kept cleaning its solar panels. A planet-wide dust storm in 2018 finally cut its power. Solar rovers live and die by dust.", "Opportunity estaba planeado para 90 días y trabajó más de 14 años: el viento limpiaba sus paneles solares. Una tormenta de polvo global en 2018 terminó por dejarlo sin energía. Los rovers solares dependen del polvo."]},
	"roubion": {"title": ["The sample that vanished", "La muestra que desapareció"], "source": "NASA · Assessing Perseverance's First Sample Attempt", "url": "https://science.nasa.gov/blog/assessing-perseverances-first-sample-attempt/",
		"text": ["Perseverance's first coring attempt, on a rock called Roubion in August 2021, came back with an empty tube: the rock had crumbled to powder. The team studied the images, chose a harder rock, Rochette, and succeeded the next month.", "El primer intento de extracción de Perseverance, en una roca llamada Roubion en agosto de 2021, devolvió un tubo vacío: la roca se había desmoronado. El equipo estudió las imágenes, eligió una roca más dura, Rochette, y lo logró al mes siguiente."]},
	"moxie": {"title": ["Oxygen, a few grams at a time", "Oxígeno, unos gramos a la vez"], "source": "NASA · MOXIE",
		"text": ["MOXIE ran 16 times on Mars and made 122 grams of oxygen in total before it finished in 2023. Small numbers, big idea: future crews could make oxygen on site.", "MOXIE funcionó 16 veces en Marte y produjo 122 gramos de oxígeno en total antes de terminar en 2023. Cifras pequeñas, idea grande: las tripulaciones futuras podrían producir oxígeno en el lugar."]},
	"delay": {"title": ["Why the rover lands alone", "Por qué el rover aterriza solo"], "source": "NASA/JPL · Mars 2020 landing press kit",
		"text": ["Entry, descent and landing take about seven minutes, but a radio signal needed about eleven minutes to reach Earth when Perseverance landed. By the time the team heard 'entry', the rover was already on the ground. It had to land itself.", "La entrada, el descenso y el aterrizaje duran unos siete minutos, pero una señal de radio tardaba unos once minutos en llegar a la Tierra cuando aterrizó Perseverance. Cuando el equipo escuchó «entrada», el rover ya estaba en el suelo. Tuvo que aterrizar solo."]}
}
const STORY_ORDER := ["wheels", "spirit", "dust", "roubion", "moxie", "delay"]

const ACHIEVEMENTS := {
	"first_launch": {"name": ["First launch", "Primer lanzamiento"], "how": ["Launch a mission.", "Lanza una misión."], "icon": "launch"},
	"touchdown": {"name": ["Wheels on Mars", "Ruedas en Marte"], "how": ["Land on Mars.", "Aterriza en Marte."], "icon": "mars"},
	"first_data": {"name": ["Earth is listening", "La Tierra escucha"], "how": ["Get your first megabyte received on Earth.", "Consigue que la Tierra reciba tu primer megabyte."], "icon": "comms"},
	"first_sample": {"name": ["First core", "Primer núcleo"], "how": ["Seal a sample in a tube.", "Sella una muestra en un tubo."], "icon": "sampling"},
	"context": {"name": ["Context first", "Primero el contexto"], "how": ["Photograph a site before sampling it.", "Fotografía un sitio antes de muestrearlo."], "icon": "science"},
	"angles": {"name": ["Every angle", "Todos los ángulos"], "how": ["Photograph one rock from 3 angles.", "Fotografía una roca desde 3 ángulos."], "icon": "science"},
	"clean_check": {"name": ["Go for launch", "Listos para lanzar"], "how": ["Launch with no blockers and no operational risks.", "Lanza sin bloqueos ni riesgos operativos."], "icon": "structure"},
	"honest": {"name": ["Evidence first", "La evidencia primero"], "how": ["Answer every interpretation question correctly in one mission.", "Responde bien todas las preguntas de interpretación en una misión."], "icon": "data"},
	"lean": {"name": ["Lean engineer", "Ingeniería austera"], "how": ["Complete a mission using under 75% of the budget.", "Completa una misión usando menos del 75% del presupuesto."], "icon": "budget"},
	"night": {"name": ["Power under control", "Energía bajo control"], "how": ["Complete a mission without entering safe mode.", "Completa una misión sin entrar en modo seguro."], "icon": "energy"},
	"recovered": {"name": ["Learn and adapt", "Aprender y adaptarse"], "how": ["Complete a mission after a failed sample.", "Completa una misión después de una muestra fallida."], "icon": "sampling"},
	"grade_s": {"name": ["Mission excellence", "Misión excelente"], "how": ["Earn grade S.", "Consigue la nota S."], "icon": "mars"},
	"all_zones": {"name": ["Four stories", "Cuatro historias"], "how": ["Complete all four zones.", "Completa las cuatro zonas."], "icon": "mars"},
	"sandbox": {"name": ["Tinkerer", "Manitas"], "how": ["Test-drive a rover in Sandbox.", "Prueba un rover en Sandbox."], "icon": "mobility"},
	"coop": {"name": ["Mission team", "Equipo de misión"], "how": ["Complete a co-op mission.", "Completa una misión en cooperativo."], "icon": "comms"},
	"curious": {"name": ["Curious mind", "Mente curiosa"], "how": ["Ask Dr. Owen for one more story.", "Pídele a la Dra. Owen una historia más."], "icon": "science", "hidden": true},
	"historian": {"name": ["Mission historian", "Historia de misiones"], "how": ["Hear every one of Dr. Owen's stories.", "Escucha todas las historias de la Dra. Owen."], "icon": "data", "hidden": true}
}
const ACHIEVEMENT_ORDER := ["first_launch", "touchdown", "first_data", "first_sample", "context", "angles", "clean_check", "honest", "lean", "night", "recovered", "grade_s", "all_zones", "sandbox", "coop", "curious", "historian"]

## Datos reales de Perseverance (NASA). Se muestran aparte de los valores del juego.
const REAL_FACTS := [
	["Perseverance carries seven science instruments: Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, MOXIE and RIMFAX.", "Perseverance lleva siete instrumentos científicos: Mastcam-Z, SuperCam, PIXL, SHERLOC, MEDA, MOXIE y RIMFAX."],
	["The rover is about 3 m long, 2.7 m wide and 2.2 m tall, with a mass of about 1,025 kg.", "El rover mide unos 3 m de largo, 2,7 m de ancho y 2,2 m de alto, con una masa de unos 1.025 kg."],
	["Its power comes from an MMRTG that supplied about 110 W at the start of the mission and charges rechargeable batteries.", "Su energía viene de un MMRTG que daba unos 110 W al inicio de la misión y carga baterías recargables."],
	["Each wheel is about 52.5 cm in diameter; the suspension is a rocker-bogie.", "Cada rueda mide unos 52,5 cm de diámetro; la suspensión es de tipo rocker-bogie."],
	["The robotic arm is about 2.1 m long and has five degrees of freedom.", "El brazo robótico mide unos 2,1 m y tiene cinco grados de libertad."],
	["Almost all science data reach Earth through Mars orbiters over a UHF link of up to about 2 Mbps. The direct X-band link to Earth is far slower: 160 to 3,000 bits per second.", "Casi todos los datos científicos llegan a la Tierra a través de orbitadores, con un enlace UHF de hasta unos 2 Mbps. El enlace directo en banda X es mucho más lento: de 160 a 3.000 bits por segundo."],
	["The rover carries 43 tubes: 38 for samples and 5 witness tubes that record possible contamination.", "El rover lleva 43 tubos: 38 para muestras y 5 tubos testigo que registran posible contaminación."],
	["NASA has not confirmed life on Mars. Habitability, potential biosignatures and confirmed evidence are different things.", "La NASA no ha confirmado vida en Marte. Habitabilidad, posibles biofirmas y evidencia confirmada son cosas distintas."]
]

const REAL_SAMPLES := [
	{"name": "Montdenier", "rock": "Rochette", "kind": ["Igneous rock", "Roca ígnea"], "number": 2, "sol": 194, "date": "2021-09-06"},
	{"name": "Hazeltop", "rock": "Wildcat Ridge", "kind": ["Sedimentary rock", "Roca sedimentaria"], "number": 12, "sol": 509, "date": "2022-07-27"},
	{"name": "Sapphire Canyon", "rock": "Cheyava Falls", "kind": ["Sedimentary rock", "Roca sedimentaria"], "number": 25, "sol": 1215, "date": "2024-07-21"},
	{"name": "Green Gardens", "rock": "Tablelands", "kind": ["Serpentinite", "Serpentinita"], "number": 27, "sol": 1433, "date": "2025-03-02"}
]
const SAMPLES_URL := "https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/"

const SOURCES := [
	["Mars 2020 Perseverance · Science Objectives", "https://science.nasa.gov/mission/mars-2020-perseverance/science-objectives/"],
	["Mars 2020 Perseverance · Science Instruments", "https://science.nasa.gov/mission/mars-2020-perseverance/science-instruments/"],
	["Mars 2020 Perseverance · Rover Components", "https://science.nasa.gov/mission/mars-2020-perseverance/rover-components/"],
	["Mars 2020 Perseverance · Mars Rock Samples", "https://science.nasa.gov/mission/mars-2020-perseverance/mars-rock-samples/"],
	["NASA · Assessing Perseverance's First Sample Attempt", "https://science.nasa.gov/blog/assessing-perseverances-first-sample-attempt/"],
	["NASA Glenn · Mars Perseverance Communications (NTRS 20210010148)", "https://ntrs.nasa.gov/api/citations/20210010148/downloads/Mars%20Perseverance%20Communications%202021%20revised.pdf"],
	["NASA/JPL · Mars 2020 Landing Press Kit · Telecommunications", "https://www.jpl.nasa.gov/news/press_kits/mars_2020/landing/mission/spacecraft/telecommunications"]
]

## Trazabilidad: fuente NASA -> información -> mecánica -> decisión -> consecuencia.
const TRACE := [
	{"src": 0, "info": ["Four science objectives: geology, astrobiology, sample caching, preparing for humans.", "Cuatro objetivos científicos: geología, astrobiología, muestras y preparación para humanos."], "mech": ["The four campaign zones and their required objectives.", "Las cuatro zonas de campaña y sus objetivos requeridos."], "dec": ["Which goal to fly and which instruments it needs.", "Qué meta volar y qué instrumentos necesita."], "cons": ["Objectives blocked when the needed instrument stays on Earth.", "Objetivos bloqueados si el instrumento necesario se queda en la Tierra."]},
	{"src": 1, "info": ["What each of the seven instruments measures; PIXL and SHERLOC ride on the arm.", "Qué mide cada uno de los siete instrumentos; PIXL y SHERLOC van en el brazo."], "mech": ["Each instrument only returns the kind of result it really supports; arm compatibility rule.", "Cada instrumento solo da el tipo de resultado que realmente soporta; regla de compatibilidad con el brazo."], "dec": ["Payload selection inside mass, budget and deck limits.", "Selección de carga útil dentro de masa, presupuesto y cubierta."], "cons": ["Different evidence, science return and data volume.", "Distinta evidencia, retorno científico y volumen de datos."]},
	{"src": 2, "info": ["MMRTG power with rechargeable batteries; rocker-bogie; antennas.", "Energía por MMRTG con baterías recargables; rocker-bogie; antenas."], "mech": ["Power source, storage, suspension and antenna trade-offs.", "Compromisos de fuente de energía, almacenamiento, suspensión y antenas."], "dec": ["Solar or RTG, more battery or less mass.", "Solar o RTG, más batería o menos masa."], "cons": ["Night survival, driving range, safe-mode events.", "Supervivencia nocturna, alcance de conducción, eventos de modo seguro."]},
	{"src": 5, "info": ["UHF relay up to 2 Mbps; orbiters visible only minutes per day; direct X-band 160-500 bps.", "Relevo UHF de hasta 2 Mbps; orbitadores visibles solo minutos al día; banda X directa 160-500 bps."], "mech": ["Orbiter pass windows, limited memory, transmission panel with real-rate estimates.", "Ventanas de paso del orbitador, memoria limitada, panel de transmisión con estimaciones a tasa real."], "dec": ["When to stop and transmit; which antenna to carry.", "Cuándo detenerse a transmitir; qué antena llevar."], "cons": ["Data left on Mars does not count; Data Return in the debrief.", "Los datos que se quedan en Marte no cuentan; Retorno de datos en el informe."]},
	{"src": 3, "info": ["Real samples are documented with site, rock type and context; 43 tubes.", "Las muestras reales se documentan con sitio, tipo de roca y contexto; 43 tubos."], "mech": ["Context photo before coring; limited tubes; sample catalogue with a real analogue link.", "Foto de contexto antes de perforar; tubos limitados; catálogo con enlace a un análogo real."], "dec": ["Which rocks deserve a tube.", "Qué rocas merecen un tubo."], "cons": ["Undocumented samples score lower.", "Las muestras sin documentar valen menos."]},
	{"src": 4, "info": ["The first coring attempt (Roubion, 2021) returned an empty tube: the rock crumbled.", "El primer intento de extracción (Roubion, 2021) devolvió un tubo vacío: la roca se desmoronó."], "mech": ["Failed-sample event on fragile rock.", "Evento de muestra fallida en roca frágil."], "dec": ["Review the images, try a harder rock or use the collector.", "Revisar las imágenes, probar una roca más dura o usar el colector."], "cons": ["Energy and time spent; a lesson instead of a penalty.", "Energía y tiempo gastados; una lección en lugar de un castigo."]}
]

static func comp(id: String) -> Dictionary:
	return COMPONENTS[id]

static func comp_name(id: String) -> String:
	return Game.tt(COMPONENTS[id].name)

static func instrument_name(id: String) -> String:
	return comp_name(id)

static func default_build() -> Dictionary:
	return {"chassis": "chassis_std", "deck": "deck_compact", "wheels": "wheels_std", "power": "solar", "computer": "cpu_basic", "arm": "", "parts": ["uhf", "mastcam", "supercam"]}

## Convierte diseños del guardado antiguo (ToMars 1.0) al catálogo nuevo sin perder decisiones.
static func migrate_build(old: Dictionary) -> Dictionary:
	if old.has("chassis") and old.has("parts"): return sanitize(old)
	var build := default_build()
	var parts: Array = ["uhf"]
	build.power = "rtg" if String(old.get("power", "solar")) == "rtg" else "solar"
	if String(old.get("battery", "small")) == "large": parts.append("battery_ext")
	build.wheels = {"standard": "wheels_std", "rugged": "wheels_reinf", "light": "wheels_light"}.get(String(old.get("wheels", "standard")), "wheels_std")
	if String(old.get("comms", "uhf")) == "hga": parts.append("hga")
	if String(old.get("computer", "standard")) == "expanded": parts.append("storage")
	for id in old.get("instruments", []):
		if String(id) == "arm":
			build.arm = "arm_std"
			parts.append("drill")
		elif COMPONENTS.has(String(id)): parts.append(String(id))
	build.parts = parts
	if payloads(build) > 4: build.deck = "deck_ext"
	return build

static func sanitize(source: Dictionary) -> Dictionary:
	var build := default_build()
	for group in GROUPS:
		var key := String(group.id)
		if group.kind == "one" and String(source.get(key, "")) in group.options: build[key] = String(source[key])
	build.arm = String(source.get("arm", "")) if String(source.get("arm", "")) in ["arm_std", "arm_ext"] else ""
	var parts: Array = []
	for id in source.get("parts", []):
		if COMPONENTS.has(String(id)) and not String(id) in parts: parts.append(String(id))
	build.parts = parts
	return build

## Lista de todos los componentes instalados.
static func installed(build: Dictionary) -> Array:
	var out: Array = []
	for key in ["chassis", "deck", "wheels", "power", "computer", "arm"]:
		if String(build.get(key, "")) != "": out.append(String(build[key]))
	for id in build.get("parts", []): out.append(String(id))
	return out

static func has(build: Dictionary, id: String) -> bool:
	if id == "arm": return String(build.get("arm", "")) != ""
	return id in installed(build)

static func instruments(build: Dictionary) -> Array:
	var out: Array = []
	for id in INSTRUMENT_ORDER:
		if id in build.get("parts", []): out.append(id)
	return out

static func payloads(build: Dictionary) -> int:
	var count := instruments(build).size()
	if has(build, "arm"): count += 1
	for id in ["drill", "regolith"]:
		if has(build, id): count += 1
	return count

static func deck_slots(build: Dictionary) -> int:
	return 8 if String(build.get("deck", "")) == "deck_ext" else 4

static func mass(build: Dictionary) -> int:
	var total := 0
	for id in installed(build): total += int(COMPONENTS[id].mass)
	return total

static func cost(build: Dictionary) -> int:
	var total := 0
	for id in installed(build): total += int(COMPONENTS[id].cost)
	return total

## Límites de la misión según el plan (perfil y ventana). En Sandbox los fija el jugador.
static func limits(plan: Dictionary) -> Dictionary:
	if plan.has("mass_cap"): return {"mass": int(plan.mass_cap), "budget": int(plan.budget_cap)}
	var profile: Dictionary = PROFILES[String(plan.get("profile", "explorer"))]
	var window: Dictionary = WINDOWS[String(plan.get("window", "optimal"))]
	return {"mass": int(profile.mass), "budget": int(profile.budget) + int(window.budget)}

static func mission_time(zone_id: String, plan: Dictionary) -> float:
	return float(ZONES[zone_id].time) * float(PROFILES[String(plan.get("profile", "explorer"))].time) * float(WINDOWS[String(plan.get("window", "optimal"))].time)

static func need_mb(zone_id: String, plan: Dictionary) -> float:
	return roundf(float(ZONES[zone_id].need_mb) * float(PROFILES[String(plan.get("profile", "explorer"))].data))

## Wh que cuesta una actividad: potencia (W del libro) x horas de misión (+ el brazo si lo usa).
static func activity_wh(build: Dictionary, id: String) -> float:
	var info: Dictionary = INSTRUMENTS[id]
	var watts := float(COMPONENTS[id].power)
	if info.arm and has(build, "arm"): watts += float(COMPONENTS[String(build.arm)].power)
	return watts * float(info.hours)

static func activity_mb(build: Dictionary, id: String) -> float:
	return float(INSTRUMENTS[id].mb) * (0.8 if has(build, "cpu_adv") else 1.0)

## Capacidades del rover derivadas del diseño (modelo educativo). Fuentes y cargas van separadas:
## la potencia de solar/RTG es GENERACIÓN; el resto de potencias son CONSUMO.
static func stats(build: Dictionary) -> Dictionary:
	var total_mass := mass(build)
	var wheels: Dictionary = COMPONENTS[String(build.wheels)]
	var chassis: Dictionary = COMPONENTS[String(build.chassis)]
	var cpu: Dictionary = COMPONENTS[String(build.computer)]
	var mobility := int(chassis.mobility) + int(wheels.mobility)
	for id in ["rocker", "navsens", "autonav"]:
		if has(build, id): mobility += int(COMPONENTS[id].mobility)
	var idle := float(cpu.power) + (float(COMPONENTS.storage.power) if has(build, "storage") else 0.0)
	var drive := float(wheels.power) * total_mass / 110.0
	if has(build, "rocker"): drive += float(COMPONENTS.rocker.power)
	if has(build, "navsens"): drive += float(COMPONENTS.navsens.power)
	var solar := String(build.power) == "solar"
	var base_speed: float = {"wheels_std": 150.0, "wheels_reinf": 128.0, "wheels_light": 182.0}[String(build.wheels)]
	return {
		"mass": total_mass,
		"speed": base_speed * (1.18 - total_mass / 1500.0),
		"mobility": mobility,
		"terrain": clampf(mobility / 80.0, 0.3, 1.0),
		"wear": (100.0 - float(wheels.rel)) / 15.0,
		"hull": (100.0 - float(chassis.rel)) / 15.0 * (0.7 if has(build, "navsens") else 1.0),
		"battery": float(MODEL.battery_wh) + (float(MODEL.battery_ext_wh) if has(build, "battery_ext") else 0.0),
		"solar": solar,
		"gen_w": float(COMPONENTS[String(build.power)].power),
		"idle_w": idle,
		"drive_w": drive,
		"night_w": idle + (float(MODEL.heater_w) if solar else 0.0),
		"memory": float(MODEL.memory_mb) + (float(MODEL.storage_mb) if has(build, "storage") else 0.0),
		"uhf": has(build, "uhf"),
		"direct": has(build, "hga"),
		"reach": 110.0 if String(build.get("arm", "")) == "arm_ext" else 70.0,
		"autonav": has(build, "autonav") and has(build, "cpu_adv"),
		"compress": has(build, "cpu_adv"),
		"science": science_potential(build)
	}

static func science_potential(build: Dictionary) -> int:
	var total := 0
	for id in installed(build): total += int(COMPONENTS[id].science)
	return total

## Wh que gasta una noche completa en reposo (45 s de juego = 7,5 h de misión).
static func night_wh(build: Dictionary) -> float:
	var s := stats(build)
	return (float(s.night_w) - (float(s.gen_w) if not s.solar else 0.0)) * 7.5

static func objective_ok(build: Dictionary, kind: String) -> Array:
	var ok := true
	var why := ["", ""]
	match kind:
		"imaged", "angles":
			ok = has(build, "mastcam")
			why = ["needs Mastcam-Z", "requiere Mastcam-Z"]
		"chem_types", "aqueous":
			ok = has(build, "supercam") or (has(build, "pixl") and has(build, "arm"))
			why = ["needs SuperCam, or PIXL with an arm", "requiere SuperCam, o PIXL con un brazo"]
		"pixl":
			ok = has(build, "pixl") and has(build, "arm")
			why = ["needs PIXL and an arm", "requiere PIXL y un brazo"]
		"sherloc":
			ok = has(build, "sherloc") and has(build, "arm")
			why = ["needs SHERLOC and an arm", "requiere SHERLOC y un brazo"]
		"quiz":
			ok = has(build, "supercam") or (has(build, "arm") and (has(build, "pixl") or has(build, "sherloc")))
			why = ["needs an instrument that reads composition", "requiere un instrumento que lea la composición"]
		"cache_types":
			ok = has(build, "arm") and has(build, "drill")
			why = ["needs an arm with the core drill", "requiere un brazo con el taladro de núcleos"]
		"cache_documented":
			ok = has(build, "arm") and has(build, "drill") and has(build, "mastcam")
			why = ["needs Mastcam-Z, an arm and the core drill", "requiere Mastcam-Z, un brazo y el taladro"]
		"regolith":
			ok = has(build, "regolith")
			why = ["needs the regolith collector", "requiere el colector de regolito"]
		"meda":
			ok = has(build, "meda")
			why = ["needs MEDA", "requiere MEDA"]
		"moxie":
			ok = has(build, "moxie")
			why = ["needs MOXIE", "requiere MOXIE"]
		"rimfax":
			ok = has(build, "rimfax")
			why = ["needs RIMFAX", "requiere RIMFAX"]
		"received":
			ok = has(build, "uhf") or has(build, "hga")
			why = ["needs an antenna", "requiere una antena"]
	return [ok, why]

## Qué objetivos de una zona puede cumplir este diseño (lo usa el informe final).
static func readiness(build: Dictionary, zone_id: String) -> Array:
	var notes: Array = []
	for objective in ZONES[zone_id].objectives:
		var result := objective_ok(build, String(objective.kind))
		notes.append({"ok": result[0], "text": objective.text, "why": result[1], "opt": bool(objective.get("opt", false))})
	return notes

## Mission Readiness: evalúa el diseño real y clasifica cada hallazgo.
##  blocker = impide lanzar · risk = se puede lanzar, la misión será más difícil
##  limit = reduce el potencial científico · tip = recomendación opcional
## Cada entrada: {level, text, why, fix(opcional: {add|remove|set, label})}
static func check(build: Dictionary, zone_id: String, plan: Dictionary) -> Array:
	var out: Array = []
	var cap := limits(plan)
	var s := stats(build)
	var zone: Dictionary = ZONES[zone_id]
	var hazards: Array = zone.hazards
	var total_mass := int(s.mass)
	var total_cost := cost(build)
	if total_mass > int(cap.mass):
		out.append({"level": "blocker", "text": ["Too heavy: %d kg over the launcher's limit.", "Demasiada masa: %d kg por encima del límite del lanzador."], "n": total_mass - int(cap.mass), "why": ["The launch vehicle cannot lift this rover. Remove or swap a heavy part.", "El vehículo de lanzamiento no puede con este rover. Quita o cambia una pieza pesada."]})
	if total_cost > int(cap.budget):
		out.append({"level": "blocker", "text": ["Over budget by %d credits.", "Presupuesto superado por %d créditos."], "n": total_cost - int(cap.budget), "why": ["Decide which capability the science really needs.", "Decide qué capacidad necesita de verdad la ciencia."]})
	if payloads(build) > deck_slots(build):
		out.append({"level": "blocker", "text": ["%d payloads do not fit on this deck.", "%d cargas útiles no caben en esta cubierta."], "n": payloads(build) - deck_slots(build), "why": ["The compact deck holds 4 payloads; the extended deck holds 8.", "La cubierta compacta admite 4 cargas útiles; la extendida, 8."], "fix": {"set": ["deck", "deck_ext"], "label": ["Fit the extended deck", "Montar la cubierta extendida"]}})
	if not s.uhf and not s.direct:
		out.append({"level": "blocker", "text": ["No antenna: the rover cannot talk to Earth.", "Sin antena: el rover no puede hablar con la Tierra."], "why": ["Without a link no command arrives and no science returns.", "Sin enlace no llegan órdenes ni vuelve la ciencia."], "fix": {"add": "uhf", "label": ["Add the UHF relay", "Añadir el relevo UHF"]}})
	for id in ["pixl", "sherloc", "drill"]:
		if has(build, id) and not has(build, "arm"):
			out.append({"level": "blocker", "text": ["%s is mounted on the arm, and there is no arm.", "%s va montado en el brazo, y no hay brazo."], "s": comp_name(id), "why": ["Incompatible design: this tool has nowhere to be installed.", "Diseño incompatible: esta herramienta no tiene dónde instalarse."], "fix": {"set": ["arm", "arm_std"], "label": ["Add the standard arm", "Añadir el brazo estándar"]}})
	if has(build, "autonav") and not has(build, "cpu_adv"):
		out.append({"level": "blocker", "text": ["AutoNav needs the advanced computer.", "AutoNav necesita la computadora avanzada."], "why": ["The basic computer cannot process terrain maps while driving.", "La computadora básica no puede procesar mapas del terreno mientras conduce."], "fix": {"set": ["computer", "cpu_adv"], "label": ["Fit the advanced computer", "Montar la computadora avanzada"]}})
	# Riesgos operativos
	if s.solar:
		var night := night_wh(build)
		var cover := float(s.battery) / maxf(1.0, night)
		if cover < 1.3:
			out.append({"level": "risk", "text": ["Night autonomy is tight: the battery covers %d%% of one night.", "Autonomía nocturna justa: la batería cubre el %d%% de una noche."], "n": int(cover * 100.0), "why": ["Solar panels give nothing at night and heaters keep running. Arrive at sunset with a full battery, or add storage.", "Los paneles no dan nada de noche y los calentadores siguen encendidos. Llega al atardecer con la batería llena, o añade almacenamiento."], "fix": {"add": "battery_ext", "label": ["Add the extended battery", "Añadir la batería extendida"]}})
		if "storm" in hazards or "cold" in hazards:
			out.append({"level": "risk", "text": ["Solar power in a zone with dust storms or cold shadows.", "Energía solar en una zona con tormentas de polvo o sombras frías."], "why": ["Storms cut sunlight and cold shadows make the heaters work harder.", "Las tormentas reducen la luz y las sombras frías exigen más a los calentadores."]})
	if float(s.drive_w) + float(s.idle_w) > float(s.gen_w) * 1.25:
		out.append({"level": "risk", "text": ["Driving draws %d W more than the rover generates.", "Conducir consume %d W más de lo que el rover genera."], "n": int(float(s.drive_w) + float(s.idle_w) - float(s.gen_w)), "why": ["Mass makes driving expensive. Long drives will drain the battery, so plan stops to recharge.", "La masa encarece la conducción. Los trayectos largos vaciarán la batería: planifica paradas para recargar."]})
	if has(build, "moxie") and float(activity_wh(build, "moxie")) - float(s.gen_w) > float(s.battery) * 0.55:
		out.append({"level": "risk", "text": ["One MOXIE run uses most of the battery.", "Una prueba de MOXIE gasta casi toda la batería."], "why": ["MOXIE draws 300 W for an hour. Run it with a full battery, in daylight.", "MOXIE consume 300 W durante una hora. Ejecútalo con la batería llena y de día."]})
	if "sharp" in hazards and float(s.wear) > 1.5:
		out.append({"level": "risk", "text": ["Lightweight wheels on sharp rock.", "Ruedas ligeras sobre roca afilada."], "why": ["Thin wheels wear twice as fast here. Curiosity's wheels were damaged this way.", "Las ruedas finas se desgastan el doble aquí. Así se dañaron las ruedas de Curiosity."]})
	if ("slope" in hazards or "sand" in hazards) and float(s.terrain) < 0.6:
		out.append({"level": "risk", "text": ["Low mobility for slopes and soft sand.", "Poca movilidad para pendientes y arena blanda."], "why": ["Without better suspension the rover will crawl there and spend more energy.", "Sin mejor suspensión el rover irá muy lento allí y gastará más energía."], "fix": {"add": "rocker", "label": ["Add the rocker-bogie", "Añadir el rocker-bogie"]}})
	if float(s.hull) > 1.5 and String(plan.get("site", "flat")) == "rough":
		out.append({"level": "risk", "text": ["A light chassis on a rough landing site.", "Un chasis ligero en un sitio de aterrizaje áspero."], "why": ["The landing will cost rover health before the mission even starts.", "El aterrizaje costará salud del rover antes de empezar la misión."]})
	if s.direct and not s.uhf:
		out.append({"level": "risk", "text": ["Direct link only: data will return slowly.", "Solo enlace directo: los datos volverán despacio."], "why": ["The relay through orbiters carries far more data than the direct link.", "El relevo por orbitadores lleva muchos más datos que el enlace directo."]})
	if float(s.memory) < need_mb(zone_id, plan) * 0.9 and not s.direct:
		out.append({"level": "risk", "text": ["Memory is smaller than the data this zone asks for.", "La memoria es menor que los datos que pide esta zona."], "why": ["You will have to stop and transmit at every orbiter pass, or data will not be recorded.", "Tendrás que detenerte a transmitir en cada paso del orbitador, o los datos no se grabarán."]})
	# Limitaciones científicas
	for objective in zone.objectives:
		var result := objective_ok(build, String(objective.kind))
		if not result[0]:
			out.append({"level": "limit" if not bool(objective.get("opt", false)) else "tip", "text": ["Out of reach: %s", "Fuera de alcance: %s"], "s": Game.tt(objective.text), "why": [String(result[1][0]).left(1).to_upper() + String(result[1][0]).substr(1) + ".", String(result[1][1]).left(1).to_upper() + String(result[1][1]).substr(1) + "."], "objective": true})
	# Recomendaciones opcionales
	if not has(build, "navsens") and String(plan.get("site", "flat")) == "rough":
		out.append({"level": "tip", "text": ["Navigation sensors would land you closer to the outcrops.", "Unos sensores de navegación te harían aterrizar más cerca de los afloramientos."], "why": ["Precision matters most on the site you chose.", "La precisión importa más en el sitio que elegiste."]})
	if int(cap.budget) - total_cost > int(cap.budget) * 0.3 and int(cap.mass) - total_mass > 40:
		out.append({"level": "tip", "text": ["You still have %d credits unspent.", "Aún te quedan %d créditos sin gastar."], "n": int(cap.budget) - total_cost, "why": ["Unused budget is fine if the science is covered. If not, it could buy memory or energy.", "Presupuesto sin usar está bien si la ciencia está cubierta. Si no, puede comprar memoria o energía."]})
	return out

static func check_text(item: Dictionary) -> String:
	var text := Game.tt(item.text)
	if item.has("n"): text = text % int(item.n)
	elif item.has("s"): text = text % String(item.s)
	return text

static func count_level(items: Array, level: String) -> int:
	return items.filter(func(item: Dictionary) -> bool: return item.level == level).size()

## Índice de preparación (0-100). Es una estimación DEL JUEGO, no una probabilidad de la NASA:
## 100 − 9 por riesgo operativo − 60 x fracción de objetivos requeridos fuera de alcance; 0 si hay bloqueos.
static func readiness_index(items: Array, zone_id: String) -> int:
	if count_level(items, "blocker") > 0: return 0
	var required := 0
	for objective in ZONES[zone_id].objectives:
		if not bool(objective.get("opt", false)): required += 1
	var value := 100.0 - 9.0 * count_level(items, "risk") - 60.0 * count_level(items, "limit") / maxf(1.0, required)
	return int(clampf(value, 5.0, 100.0))

## Recomendaciones adaptativas a partir del historial REAL guardado. No cambian el diseño.
static func recommendations(history: Array) -> Array:
	var out: Array = []
	if history.is_empty():
		out.append({"issue": ["First mission", "Primera misión"], "why": ["No flight history yet.", "Aún no hay historial de vuelo."], "tip": ["Start simple: a camera, a composition instrument and an antenna cover the Crater Floor. Check Mission Readiness before you launch.", "Empieza simple: una cámara, un instrumento de composición y una antena cubren el Suelo del cráter. Revisa Mission Readiness antes de lanzar."]})
		return out
	var recent: Array = history.slice(maxi(0, history.size() - 4))
	var count := func(key: String) -> int:
		var total := 0
		for entry in recent:
			if float(entry.get("flags", {}).get(key, 0)) > 0.0: total += 1
		return total
	var n: int = recent.size()
	var word := func(times: int) -> Array: return ["%d of your last %d missions" % [times, n], "%d de tus últimas %d misiones" % [times, n]]
	if count.call("safe") > 0:
		var w: Array = word.call(count.call("safe"))
		out.append({"issue": ["Energy", "Energía"], "why": ["The rover ran out of power and entered safe mode in %s." % w[0], "El rover se quedó sin energía y entró en modo seguro en %s." % w[1]], "tip": ["More storage (Extended Battery) or steady power (RTG) would have covered those hours. Lighter mass also lowers the cost of every drive.", "Más almacenamiento (Batería extendida) o energía constante (RTG) habría cubierto esas horas. Menos masa también abarata cada trayecto."]})
	if count.call("mem_full") > 0:
		var w2: Array = word.call(count.call("mem_full"))
		out.append({"issue": ["Data storage", "Almacenamiento de datos"], "why": ["Memory filled up and data could not be recorded in %s." % w2[0], "La memoria se llenó y no se pudieron grabar datos en %s." % w2[1]], "tip": ["Large Storage adds room between passes; the Advanced Computer compresses data. Or transmit at every orbiter pass.", "Almacenamiento grande da espacio entre pasos; la Computadora avanzada comprime los datos. O transmite en cada paso del orbitador."]})
	if count.call("left") > 0:
		var w3: Array = word.call(count.call("left"))
		out.append({"issue": ["Communications", "Comunicaciones"], "why": ["Science stayed on the rover, never transmitted, in %s." % w3[0], "Quedó ciencia en el rover, sin transmitir, en %s." % w3[1]], "tip": ["A second antenna gives a link outside orbiter passes. Leave time for one last transmission before the mission ends.", "Una segunda antena da enlace fuera de los pasos del orbitador. Deja tiempo para una última transmisión antes de terminar la misión."]})
	if count.call("damage") > 0:
		var w4: Array = word.call(count.call("damage"))
		out.append({"issue": ["Mobility & terrain", "Movilidad y terreno"], "why": ["The rover lost more than 40% health in %s." % w4[0], "El rover perdió más del 40% de salud en %s." % w4[1]], "tip": ["Reinforced wheels resist sharp rock; a stronger chassis and navigation sensors soften collisions.", "Las ruedas reforzadas resisten la roca afilada; un chasis más fuerte y sensores de navegación suavizan los choques."]})
	if count.call("blocked") > 0:
		var w5: Array = word.call(count.call("blocked"))
		out.append({"issue": ["Science", "Ciencia"], "why": ["Required objectives were out of reach for the design in %s." % w5[0], "Hubo objetivos requeridos fuera del alcance del diseño en %s." % w5[1]], "tip": ["Read the limitations in Mission Readiness: each one names the instrument that would unlock it.", "Lee las limitaciones en Mission Readiness: cada una nombra el instrumento que la resolvería."]})
	if count.call("timeout") > 0:
		var w6: Array = word.call(count.call("timeout"))
		out.append({"issue": ["Time", "Tiempo"], "why": ["Mission time ran out before the required objectives in %s." % w6[0], "El tiempo de misión se agotó antes de cumplir los objetivos requeridos en %s." % w6[1]], "tip": ["A lighter, faster rover, AutoNav or a landing site nearer the outcrops saves driving time.", "Un rover más ligero y rápido, AutoNav o un sitio de aterrizaje más cercano a los afloramientos ahorran tiempo de conducción."]})
	if count.call("overbuilt") > 1:
		out.append({"issue": ["Budget & mass", "Presupuesto y masa"], "why": ["You carried instruments that the mission never used.", "Llevaste instrumentos que la misión nunca usó."], "tip": ["Unused payload is mass and budget that could have bought energy or memory.", "La carga sin usar es masa y presupuesto que podrían haber comprado energía o memoria."]})
	if out.is_empty():
		out.append({"issue": ["Steady performance", "Rendimiento estable"], "why": ["No recurring problem in your recent missions.", "No hay problemas repetidos en tus misiones recientes."], "tip": ["Try a leaner design or a harder profile, and see what you can still discover.", "Prueba un diseño más austero o un perfil más exigente, y mira qué logras descubrir."]})
	return out
