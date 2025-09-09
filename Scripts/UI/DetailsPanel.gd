extends Panel

"""
DetailsPanel - Panel de detalles unificado para mostrar información de unidades
Integra la funcionalidad de DivisionPanel en el MainHUD
"""

# Referencias a nodos
@onready var title_label: Label = $VBoxContainer/HeaderContainer/TitleLabel
@onready var close_button: Button = $VBoxContainer/HeaderContainer/CloseButton
@onready var content_container: VBoxContainer = $VBoxContainer/ContentContainer/DetailsContent

# Instancia del panel de división para mostrar detalles completos
var division_panel_instance: Node = null
var current_division_data: DivisionData = null

signal panel_closed()

func _ready():
	"""Inicialización del panel"""
	close_button.pressed.connect(_on_close_pressed)
	
	# Cargar el DivisionPanel como recurso
	var division_panel_scene = preload("res://Scenes/UI/DivisionPanel.tscn")
	if division_panel_scene:
		division_panel_instance = division_panel_scene.instantiate()
		content_container.add_child(division_panel_instance)
		division_panel_instance.visible = false
		print("✅ DivisionPanel integrado en DetailsPanel")

func mostrar_detalles_division(division_data: DivisionData):
	"""Muestra los detalles completos de una división"""
	if not division_data:
		push_error("❌ No se proporcionaron datos de división")
		return
	
	current_division_data = division_data
	title_label.text = "División: " + division_data.nombre
	
	# Limpiar contenido anterior
	for child in content_container.get_children():
		if child != division_panel_instance:
			child.queue_free()
	
	# Mostrar el panel de división si está disponible
	if division_panel_instance and division_panel_instance.has_method("mostrar_composicion"):
		division_panel_instance.visible = true
		division_panel_instance.mostrar_composicion(division_data)
		print("✅ Mostrando detalles de división:", division_data.nombre)
	else:
		# Fallback: mostrar información básica
		mostrar_informacion_basica(division_data)
	
	visible = true

func mostrar_informacion_basica(division_data: DivisionData):
	"""Muestra información básica cuando no está disponible el DivisionPanel"""
	var info_container = VBoxContainer.new()
	
	var basic_info = {
		"Nombre": division_data.nombre,
		"Facción": division_data.faccion,
		"Rama Principal": division_data.rama_principal,
		"Cantidad Total": str(division_data.cantidad_total),
		"Movilidad": str(division_data.movilidad),
		"Moral": str(division_data.moral),
		"Experiencia": str(division_data.experiencia),
		"Estado": division_data.estado if division_data.get("estado") else "Activo"
	}
	
	for key in basic_info:
		var info_line = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = str(key) + ":"
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_font_size_override("font_size", 12)
		
		var value_label = Label.new()
		value_label.text = str(basic_info[key])
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 12)
		
		info_line.add_child(key_label)
		info_line.add_child(value_label)
		info_container.add_child(info_line)
	
	content_container.add_child(info_container)

func mostrar_detalles_genericos(titulo: String, datos: Dictionary):
	"""Muestra detalles genéricos para otros tipos de objetos"""
	current_division_data = null
	title_label.text = titulo
	
	# Ocultar el panel de división
	if division_panel_instance:
		division_panel_instance.visible = false
	
	# Limpiar contenido anterior
	for child in content_container.get_children():
		if child != division_panel_instance:
			child.queue_free()
	
	# Agregar información genérica
	for key in datos:
		var info_line = HBoxContainer.new()
		
		var key_label = Label.new()
		key_label.text = str(key) + ":"
		key_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		key_label.add_theme_font_size_override("font_size", 12)
		
		var value_label = Label.new()
		value_label.text = str(datos[key])
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.add_theme_font_size_override("font_size", 12)
		
		info_line.add_child(key_label)
		info_line.add_child(value_label)
		content_container.add_child(info_line)
	
	visible = true

func ocultar():
	"""Oculta el panel de detalles"""
	visible = false
	current_division_data = null
	if division_panel_instance:
		division_panel_instance.visible = false

func _on_close_pressed():
	"""Callback para el botón de cerrar"""
	ocultar()
	emit_signal("panel_closed")

func obtener_division_actual() -> DivisionData:
	"""Obtiene la división actualmente mostrada"""
	return current_division_data

func actualizar_detalles():
	"""Actualiza los detalles si hay una división seleccionada"""
	if current_division_data:
		mostrar_detalles_division(current_division_data)