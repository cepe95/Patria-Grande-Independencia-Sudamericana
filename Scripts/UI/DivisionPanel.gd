extends Panel

var division_data: DivisionData

@onready var title_label = $TitleLabel
@onready var faction_label = $FactionLabel
@onready var main_branch_label = $MainBranchLabel
@onready var commander_icon = $CommanderContainer/CommanderIcon
@onready var commander_label = $CommanderContainer/CommanderLabel
@onready var stats_grid = $StatsGrid
@onready var state_label = $StateLabel
@onready var location_label = $LocationLabel
@onready var supply_label = $SupplyLabel
@onready var created_label = $CreatedLabel
@onready var history_label = $HistoryLabel
@onready var mission_label = $MissionLabel
@onready var unit_list = $UnitList
@onready var btn_fusionar = $BtnFusionar
@onready var btn_cerrar = $BtnCerrar

func _ready() -> void:
	btn_fusionar.pressed.connect(fusionar_seleccionadas)
	btn_cerrar.pressed.connect(func(): hide())

func mostrar_composicion(data: DivisionData) -> void:
	division_data = data
	title_label.text = data.nombre
	faction_label.text = "Facción: %s" % data.faccion
	main_branch_label.text = "Rama: %s" % data.rama_principal
	commander_label.text = data.comandante.nombre if data.comandante else "Sin comandante"
	commander_icon.texture = data.comandante.icono if data.comandante and data.comandante.icono else null

	set_stat("Cantidad total", str(data.cantidad_total))
	set_stat("Movilidad", str(data.movilidad))
	set_stat("Moral", str(data.moral))
	set_stat("Experiencia", str(data.experiencia))
	set_stat("Condición física", str(data.condicion_fisica))
	set_stat("Bajas recientes", str(data.bajas_recientes))
	set_stat("Nivel de refuerzos", str(data.nivel_refuerzos))

	state_label.text = "Estado: %s" % (data.estado_actual if data.estado_actual else "Desconocido")
	location_label.text = "Ubicación: %s" % (data.ubicacion if data.ubicacion else "Desconocida")
	supply_label.text = "Suministros: %s" % (data.suministro if data.suministro else "Desconocido")
	created_label.text = "Creada: %s" % (data.fecha_creacion if data.fecha_creacion else "Desconocida")
	history_label.text = "Batallas recientes: %s" % (", ".join(data.historial_batallas) if data.historial_batallas else "Ninguna")
	mission_label.text = "Misión: %s" % (data.mision if data.mision else "Sin misión")

	unit_list.clear()
	for unidad in data.unidades_componentes:
		var entrada := crear_entrada(unidad)
		unit_list.add_child(entrada)

	show()

func set_stat(nombre: String, valor: String) -> void:
	for i in range(0, stats_grid.get_child_count(), 2):
		var stat_label = stats_grid.get_child(i) as Label
		if stat_label.text.begins_with(nombre):
			var value_label = stats_grid.get_child(i + 1) as Label
			value_label.text = valor
			return

func crear_entrada(unit_data: UnitData) -> Control:
	var hbox := HBoxContainer.new()

	var check := CheckBox.new()
	check.focus_mode = Control.FOCUS_NONE

	var icon := TextureRect.new()
	icon.texture = unit_data.icono if unit_data.icono else null
	icon.custom_min_size = Vector2(32, 32)

	var label := Label.new()
	label.text = "%s (%d) | Moral: %d | Exp: %d" % [unit_data.nombre, unit_data.tamaño, unit_data.moral, unit_data.experiencia]

	var btn := Button.new()
	btn.text = "Quitar"
	btn.pressed.connect(func(): quitar_unidad(unit_data))

	hbox.add_child(check)
	hbox.add_child(icon)
	hbox.add_child(label)
	hbox.add_child(btn)

	hbox.set_meta("unit_data", unit_data)
	hbox.set_meta("check", check)

	return hbox

func quitar_unidad(unit_data: UnitData) -> void:
	# Nuevo: Agregar a subunidades libres globales
	if has_node("/root/StrategicMap"):
		var strategic_map = get_node("/root/StrategicMap")
		strategic_map.agregar_subunidad_libre(unit_data)
	else:
		push_warning("No se encontró StrategicMap como autoload. Corrige la referencia si es necesario.")

	division_data.unidades_componentes.erase(unit_data)
	division_data.cantidad_total -= unit_data.tamaño

	mostrar_composicion(division_data)

func fusionar_seleccionadas() -> void:
	var seleccionadas := []

	for entrada in unit_list.get_children():
		var check := entrada.get_meta("check") as CheckBox
		if check and check.button_pressed:
			var unit := entrada.get_meta("unit_data") as UnitData
			seleccionadas.append(unit)

	if seleccionadas.size() < 2:
		return

	var utils := preload("res://scripts/strategic/UnitUtils.gd").new()
	var fusionada := utils.fusionar_unidades(seleccionadas)

	if fusionada == null:
		return

	# Instanciar la unidad fusionada en el mapa (opcional, según tu flujo)
	var instancia := preload("res://Scenes/Strategic/UnitInstance.tscn").instantiate()
	instancia.set_data(fusionada)
	instancia.global_position = global_position + Vector2(randf() * 20 - 10, randf() * 20 - 10)
	get_tree().current_scene.add_child(instancia)

	for u in seleccionadas:
		division_data.unidades_componentes.erase(u)
		division_data.cantidad_total -= u.tamaño

	mostrar_composicion(division_data)
