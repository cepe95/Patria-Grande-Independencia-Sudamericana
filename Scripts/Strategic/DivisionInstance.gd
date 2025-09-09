extends Control

signal division_seleccionada(division)
signal division_movida(division, nueva_posicion)
signal solicitar_accion(division, tipo_accion)

var data: DivisionData = null
var detail: DivisionData = null

# Variables para manejo de movimiento
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var is_selected: bool = false

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var label: Label = get_node_or_null("Label")
@onready var icon: TextureRect = get_node_or_null("Icon")
@onready var units_container: VBoxContainer = get_node_or_null("UnitsContainer") # Contenedor para unidades

func set_button_data(_data_param: DivisionData) -> void:
	data = _data_param

	if not data:
		push_error("⚠ El parámetro 'data' está vacío o no fue asignado correctamente")
		return
	if not icon:
		push_error("⚠ Nodo 'Icon' no encontrado en DivisionInstance")
		return

	match data.faccion:
		"Patriota":
			icon.texture = load("res://Assets/Icons/Division Patriota.png") as Texture2D
		"Realista":
			icon.texture = load("res://Assets/Icons/Division Realista.png") as Texture2D
		_:
			push_warning("⚠️ Facción desconocida: %s" % str(data.faccion))
			icon.texture = load("res://Assets/Icons/Division Patriota.png") as Texture2D

	if label:
		label.text = "%s (%d)" % [data.nombre, data.cantidad_total]

	# Mostrar la composición de unidades
	mostrar_composicion_unidades()

func mostrar_composicion_unidades() -> void:
	if not data or not units_container:
		return

	# Limpiar contenedor
	for child in units_container.get_children():
		child.queue_free()

	# Instanciar cada unidad como Label o pequeño icono
	for unidad_data in data.unidades_componentes:
		if not unidad_data:
			continue
		var unidad_label = Label.new()
		unidad_label.text = unidad_data.nombre
		unidad_label.add_theme_color_override("font_color", Color(1,1,1))
		units_container.add_child(unidad_label)

func mostrar_panel_composicion():
	if not data:
		push_error("⚠ No hay 'data' para mostrar en el panel de composición")
		return
	
	var panel := get_tree().current_scene.get_node_or_null("UI/DivisionPanel")
	if panel:
		panel.mostrar_composicion(data)

func mover_a(destino: Vector2):
	"""Mueve la división a un destino específico con animación"""
	if validar_posicion(destino):
		var tween := create_tween()
		tween.tween_property(self, "global_position", destino, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
		emit_signal("division_movida", self, destino)
	else:
		print("❌ No se puede mover a la posición:", destino)

func obtener_posicion() -> Vector2:
	"""Obtiene la posición actual de la división"""
	return global_position

func obtener_datos() -> DivisionData:
	"""Obtiene los datos de la división"""
	return data

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Inicio del arrastre
				print("✔ División clickeada:", data.nombre)
				emit_signal("division_seleccionada", self)
				resaltar_seleccion(true)
				
				# Preparar para arrastre
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				original_position = global_position
				
			else:
				# Fin del arrastre
				if is_dragging:
					is_dragging = false
					var nueva_posicion = global_position
					
					# Validar posición con el mapa estratégico
					if validar_posicion(nueva_posicion):
						print("✅ División movida a:", nueva_posicion)
						emit_signal("division_movida", self, nueva_posicion)
					else:
						# Revertir a posición original si no es válida
						print("❌ Movimiento inválido, revirtiendo")
						global_position = original_position
		
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			# Menú contextual para acciones futuras
			if is_selected:
				mostrar_menu_acciones()
	
	elif event is InputEventMouseMotion and is_dragging:
		# Actualizar posición durante el arrastre
		global_position = get_global_mouse_position() + drag_offset

func validar_posicion(posicion: Vector2) -> bool:
	"""Valida si la posición está dentro de los límites del mapa"""
	var strategic_map = get_tree().current_scene.get_node_or_null("StrategicMap")
	if not strategic_map:
		strategic_map = get_tree().current_scene
	
	if strategic_map and strategic_map.has_method("validar_posicion_unidad"):
		return strategic_map.validar_posicion_unidad(posicion)
	
	# Validación básica por defecto (límites amplios)
	return posicion.x > -2000 and posicion.x < 2000 and posicion.y > -2000 and posicion.y < 2000

func mostrar_menu_acciones():
	"""Muestra un menú contextual para acciones futuras (atacar, fortificar, etc.)"""
	print("🎯 Menú de acciones para:", data.nombre)
	# TODO: Implementar menú contextual
	# Emitir señales para diferentes acciones
	emit_signal("solicitar_accion", self, "menu_contextual")

func resaltar_seleccion(activo: bool):
	is_selected = activo
	if activo:
		self.modulate = Color(0.5, 0.5, 1) # Azul
		# Agregar un efecto visual opcional
		var tween = create_tween()
		tween.set_loops(2)
		tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.1)
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		self.modulate = Color(1, 1, 1)   # Normal

func obtener_area_visual() -> Rect2:
	if sprite and sprite.texture:
		return Rect2(global_position - sprite.texture.get_size() / 2, sprite.texture.get_size())
	return Rect2(global_position, Vector2.ZERO)

func consumir_recursos(delta: float) -> void:
	if not data:
		return
	
	var fac := FactionManager.obtener_faccion(data.faccion)
	if not fac:
		return

	if not data.unidades_componentes:
		return

	for unidad in data.unidades_componentes:
		if not unidad or not unidad.consumo:
			continue
		for recurso in unidad.consumo.keys():
			var cantidad: float = unidad.consumo[recurso] * unidad.cantidad * delta
			if fac.recursos.has(recurso):
				fac.recursos[recurso] -= cantidad

func _process(delta: float) -> void:
	consumir_recursos(delta)
