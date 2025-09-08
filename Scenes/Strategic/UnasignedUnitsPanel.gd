extends Panel

@onready var unit_list := $UnitList  # VBoxContainer en la escena
@onready var title_label := $TitleLabel  # Opcional: Label para el título

func _ready():
	mostrar_subunidades_libres()

func mostrar_subunidades_libres():
	# Limpia la lista
	unit_list.clear()

	# Obtén las subunidades libres desde el StrategicMap global (autoload)
	var strategic_map = get_node("/root/StrategicMap")
	var libres = strategic_map.get_subunidades_libres()

	# Opcional: mostrar la cantidad en el título
	if title_label:
		title_label.text = "Subunidades Libres (%d)" % libres.size()

	for unit_data in libres:
		var entrada = crear_entrada(unit_data)
		unit_list.add_child(entrada)

func crear_entrada(unit_data: UnitData) -> Control:
	var hbox := HBoxContainer.new()

	var icon := TextureRect.new()
	icon.texture = unit_data.icono if unit_data.icono else null
	icon.custom_min_size = Vector2(32, 32)

	var label := Label.new()
	label.text = "%s (%d) | Moral: %d | Exp: %d" % [unit_data.nombre, unit_data.tamaño, unit_data.moral, unit_data.experiencia]

	var btn := Button.new()
	btn.text = "Asignar a división"
	btn.pressed.connect(func(): asignar_a_division(unit_data))

	hbox.add_child(icon)
	hbox.add_child(label)
	hbox.add_child(btn)

	return hbox

func asignar_a_division(unit_data: UnitData):
	# Asigna la subunidad a la división seleccionada, si hay una
	var strategic_map = get_node("/root/StrategicMap")
	var division_sel = strategic_map.division_seleccionada
	if division_sel and division_sel.data:
		strategic_map.quitar_subunidad_libre(unit_data)
		division_sel.data.unidades_componentes.append(unit_data)
		division_sel.data.cantidad_total += unit_data.tamaño

		# Refresca paneles
		mostrar_subunidades_libres()
		if has_node("/root/DivisionPanel"):
			get_node("/root/DivisionPanel").mostrar_composicion(division_sel.data)
	else:
		push_warning("No hay división seleccionada para asignar la subunidad.")

# Llama a esta función desde StrategicMap.actualizar_panel_subunidades_libres()
