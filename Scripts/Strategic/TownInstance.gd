extends Area2D

# Señal emitida cuando una división llega exactamente al pueblo (para reclutamiento)
signal division_en_pueblo(division, town)
# Señal emitida cuando una división sale del pueblo
signal division_sale_pueblo(division, town)

var town_data: TownData
var panel : Control = null
var recursos_generados := 0
const TownData = preload("res://Data/TownData.gd")

const RANGO_CAPTURA := 100.0
const RANGO_RECLUTAMIENTO := 50.0  # Rango más estricto para reclutamiento

# Lista de divisiones actualmente en el pueblo (para reclutamiento)
var divisiones_en_pueblo: Array = []

func set_data(data: TownData):
	town_data = data
	name = town_data.nombre

func _ready():
	connect("input_event", _on_input_event)
	crear_panel_flotante()
	set_process(true)
	# Agregar al grupo "towns" para detección por el sistema de reclutamiento
	add_to_group("towns")

func _process(delta):
	detectar_unidades_cercanas()
	detectar_divisiones_para_reclutamiento()
	if town_data.estado == "controlado":
		generar_recursos(delta)

func detectar_unidades_cercanas():
	var mapa := get_tree().current_scene
	for unidad in mapa.get_tree().get_nodes_in_group("unidades"):
		if position.distance_to(unidad.position) <= RANGO_CAPTURA:
			if town_data.estado != "controlado":
				town_data.estado = "controlado"
				actualizar_panel()
				print("Poblado capturado:", town_data.nombre)

func detectar_divisiones_para_reclutamiento():
	"""Detecta divisiones exactamente en el pueblo para permitir reclutamiento"""
	var mapa := get_tree().current_scene
	var divisiones_actuales: Array = []
	
	# Buscar todas las divisiones dentro del rango de reclutamiento
	for unidad in mapa.get_tree().get_nodes_in_group("unidades"):
		if position.distance_to(unidad.position) <= RANGO_RECLUTAMIENTO:
			divisiones_actuales.append(unidad)
	
	# Detectar nuevas divisiones que llegaron al pueblo
	for division in divisiones_actuales:
		if division not in divisiones_en_pueblo:
			divisiones_en_pueblo.append(division)
			emit_signal("division_en_pueblo", division, self)
			print("✅ División en pueblo para reclutamiento:", division.data.nombre, "en", town_data.nombre)
	
	# Detectar divisiones que salieron del pueblo
	for division in divisiones_en_pueblo.duplicate():
		if division not in divisiones_actuales:
			divisiones_en_pueblo.erase(division)
			emit_signal("division_sale_pueblo", division, self)
			print("❌ División salió del pueblo:", division.data.nombre, "de", town_data.nombre)

func generar_recursos(delta):
	recursos_generados += delta * town_data.importancia
	# Podés redondear o acumular según tu sistema de economía

func _on_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		panel.visible = true

func crear_panel_flotante():
	panel = Control.new()
	panel.name = "PanelInfo"
	panel.visible = false
	panel.position = Vector2(0, -80)

	var fondo := ColorRect.new()
	fondo.color = Color(0, 0, 0, 0.7)
	fondo.size = Vector2(160, 60)
	panel.add_child(fondo)

	var texto := Label.new()
	texto.text = "%s\nTipo: %s\nImportancia: %d" % [town_data.nombre, town_data.tipo, town_data.importancia]
	texto.position = Vector2(10, 10)
	panel.add_child(texto)

	add_child(panel)

func actualizar_panel():
	if panel:
		var texto := panel.get_node_or_null("Label")
		if texto:
			texto.text = "%s\nTipo: %s\nImportancia: %d\nEstado: %s\nRecursos: %s\nManpower: %d\nUnidades: %s\nOficiales: %s\n%s" % [
				town_data.nombre,
				town_data.tipo,
				town_data.importancia,
				town_data.estado,
				", ".join(town_data.recursos),
				town_data.manpower,
				", ".join(town_data.unidades_sostenibles),
				", ".join(town_data.oficiales_disponibles),
				town_data.comentario
			]
func obtener_unidades_reclutables() -> Array:
	"""Retorna las unidades que se pueden reclutar en este pueblo"""
	var unidades_disponibles: Array = []
	
	# Verificar si el pueblo puede sostener unidades
	if town_data.unidades_sostenibles.size() == 0:
		return unidades_disponibles
	
	# Cargar las unidades disponibles basadas en el tipo de pueblo
	match town_data.tipo:
		"villa", "pueblo", "ciudad_pequeña":
			# Solo pelotón disponible en villas
			if "Pelotón" in town_data.unidades_sostenibles:
				var peloton = load("res://Data/Units/Infantería/Pelotón.tres")
				if peloton:
					unidades_disponibles.append(peloton)
		"ciudad_mediana":
			# Pelotón y Compañía en ciudades medianas
			if "Pelotón" in town_data.unidades_sostenibles:
				var peloton = load("res://Data/Units/Infantería/Pelotón.tres")
				if peloton:
					unidades_disponibles.append(peloton)
			if "Compañía" in town_data.unidades_sostenibles:
				var compania = load("res://Data/Units/Infantería/Compañia.tres")
				if compania:
					unidades_disponibles.append(compania)
		"ciudad_grande":
			# Compañía y Batallón en ciudades grandes
			if "Compañía" in town_data.unidades_sostenibles:
				var compania = load("res://Data/Units/Infantería/Compañia.tres")
				if compania:
					unidades_disponibles.append(compania)
			if "Batallón" in town_data.unidades_sostenibles:
				var batallon = load("res://Data/Units/Infantería/Batallón.tres")
				if batallon:
					unidades_disponibles.append(batallon)
			# También agregar caballería en ciudades grandes
			var escuadron = load("res://Data/Units/Caballería/Escuadrón.tres")
			if escuadron:
				unidades_disponibles.append(escuadron)
		"capital", "metropolis":
			# Todas las unidades disponibles en capitales
			var peloton = load("res://Data/Units/Infantería/Pelotón.tres")
			if peloton:
				unidades_disponibles.append(peloton)
			var compania = load("res://Data/Units/Infantería/Compañia.tres")
			if compania:
				unidades_disponibles.append(compania)
			var batallon = load("res://Data/Units/Infantería/Batallón.tres")
			if batallon:
				unidades_disponibles.append(batallon)
			var escuadron = load("res://Data/Units/Caballería/Escuadrón.tres")
			if escuadron:
				unidades_disponibles.append(escuadron)
			var regimiento_cab = load("res://Data/Units/Caballería/Regimiento.tres")
			if regimiento_cab:
				unidades_disponibles.append(regimiento_cab)
	
	return unidades_disponibles

func configurar_por_tipo():
	match town_data.tipo:
		"villa", "pueblo", "ciudad_pequeña":
			town_data.recursos = ["Comida", "carne", "fruta", "verdura", "vino", "aguardiente", "tabaco"]
			town_data.manpower = 50
			town_data.unidades_sostenibles = ["Pelotón"]
			town_data.oficiales_disponibles = ["Teniente"]
			town_data.comentario = "Base de tropas básicas, limitada capacidad de liderazgo"
		"ciudad_mediana":
			town_data.recursos = ["Alimentos", "manufactura ligera", "armas simples", "oro/dinero"]
			town_data.manpower = 150
			town_data.unidades_sostenibles = ["Pelotón", "Compañía"]
			town_data.oficiales_disponibles = ["Teniente", "Capitán"]
			town_data.comentario = "Ciudad balanceada, permite reclutar tropas y oficiales de nivel medio"
		"ciudad_grande":
			town_data.recursos = ["Alimentos", "manufactura avanzada", "armas", "cañones", "pólvora", "munición", "oro/plata/dinero"]
			town_data.manpower = 450
			town_data.unidades_sostenibles = ["Compañía", "Batallón"]
			town_data.oficiales_disponibles = ["Teniente", "Capitán", "Teniente Coronel"]
			town_data.comentario = "Centro estratégico con producción militar avanzada y oficiales de rango medio-alto"
		"capital", "metropolis":
			town_data.recursos = ["Todos"]
			town_data.manpower = 1000
			town_data.unidades_sostenibles = ["Pelotón", "Compañía", "Batallón", "Brigada"]
			town_data.oficiales_disponibles = ["Teniente", "Capitán", "Teniente Coronel", "General"]
			town_data.comentario = "Centro neurálgico del ejército y producción estratégica, vital para control territorial y campañas"
