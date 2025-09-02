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
		var texto := panel.get_node("Label")
		if texto:
			texto.text = "%s\nTipo: %s\nImportancia: %d\nEstado: %s" % [
				town_data.nombre,
				town_data.tipo,
				town_data.importancia,
				town_data.estado
			]
