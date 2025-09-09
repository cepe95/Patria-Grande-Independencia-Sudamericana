extends Area2D

var town_data: TownData
var panel : Control = null
var recursos_generados := 0
const TownData = preload("res://Data/TownData.gd")

const RANGO_CAPTURA := 100.0

func set_data(data: TownData):
	town_data = data
	name = town_data.nombre

func _ready():
	connect("input_event", _on_input_event)
	crear_panel_flotante()
	set_process(true)

func _process(delta):
	detectar_unidades_cercanas()
	# Generación de recursos movida al sistema de ticks
	# if town_data.estado == "controlado":
	# 	generar_recursos(delta)

func detectar_unidades_cercanas():
	var mapa := get_tree().current_scene
	for unidad in mapa.get_tree().get_nodes_in_group("unidades"):
		if position.distance_to(unidad.position) <= RANGO_CAPTURA:
			if town_data.estado != "controlado":
				town_data.estado = "controlado"
				actualizar_panel()
				print("Poblado capturado:", town_data.nombre)

func generar_recursos(delta):
	recursos_generados += delta * town_data.importancia
	# Podés redondear o acumular según tu sistema de economía

func generar_recursos_tick():
	"""Genera recursos por tick y los agrega a la facción controladora"""
	if town_data.estado != "controlado":
		return
		
	# Determinar qué facción controla el pueblo (por simplicidad, asumiremos Patriota)
	var faccion_controladora = FactionManager.obtener_faccion("Patriota")
	if not faccion_controladora:
		return
	
	# Generar recursos basados en la importancia del pueblo
	var recursos_por_tick = town_data.importancia
	
	print("🏘️ %s genera recursos (importancia: %d)" % [town_data.nombre, town_data.importancia])
	
	# Agregar recursos básicos según el tipo de pueblo
	match town_data.tipo:
		"pueblo_pequeno":
			faccion_controladora.recursos["pan"] += recursos_por_tick * 1
			faccion_controladora.recursos["dinero"] += recursos_por_tick * 0.5
		"ciudad_mediana":
			faccion_controladora.recursos["pan"] += recursos_por_tick * 2
			faccion_controladora.recursos["dinero"] += recursos_por_tick * 1
			faccion_controladora.recursos["municion"] += recursos_por_tick * 0.5
		"ciudad_grande":
			faccion_controladora.recursos["pan"] += recursos_por_tick * 3
			faccion_controladora.recursos["dinero"] += recursos_por_tick * 2
			faccion_controladora.recursos["municion"] += recursos_por_tick * 1
			faccion_controladora.recursos["polvora"] += recursos_por_tick * 0.5
		_:
			# Pueblo genérico
			faccion_controladora.recursos["pan"] += recursos_por_tick * 1
			faccion_controladora.recursos["dinero"] += recursos_por_tick * 0.5

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
