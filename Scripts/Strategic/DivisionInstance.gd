"""
DivisionInstance.gd

Clase que maneja las instancias de divisiones en el mapa estratégico.
Implementa funcionalidad de selección, arrastre, movimiento y acciones futuras.

Características principales:
- Selección visual con retroalimentación
- Sistema de arrastre y colocación con validación
- Indicadores visuales de movimiento y área válida
- Señales para acciones futuras (atacar, fortificar, etc.)
- Validación de rango de movimiento basado en movilidad

Señales emitidas:
- division_seleccionada(division): Cuando se selecciona la división
- division_movida(division, nueva_posicion): Cuando se mueve la división
- solicitar_accion(division, tipo_accion): Para acciones futuras

Autor: Sistema de movimiento implementado por Copilot
"""

extends Control

# === SEÑALES ===
signal division_seleccionada(division)
signal division_movida(division, nueva_posicion)
signal solicitar_accion(division, tipo_accion)

# === DATOS ===
var data: DivisionData = null
var detail: DivisionData = null

# === VARIABLES DE MOVIMIENTO ===
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 = Vector2.ZERO
var is_selected: bool = false

# === INDICADORES VISUALES ===
var movement_indicator: Node2D = null
var valid_area_indicator: Control = null

# === REFERENCIAS A NODOS ===
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var label: Label = get_node_or_null("Label")
@onready var icon: TextureRect = get_node_or_null("Icon")
@onready var units_container: VBoxContainer = get_node_or_null("UnitsContainer") # Contenedor para unidades

func _ready():
	"""Inicialización de la instancia de división"""
	# Configurar indicadores visuales
	setup_visual_indicators()

func setup_visual_indicators():
	"""Configura los indicadores visuales para movimiento"""
	# Crear indicador de área de movimiento válida
	valid_area_indicator = ColorRect.new()
	valid_area_indicator.color = Color(0, 1, 0, 0.2)  # Verde semitransparente
	valid_area_indicator.size = Vector2(100, 100)
	valid_area_indicator.position = Vector2(-50, -50)
	valid_area_indicator.visible = false
	add_child(valid_area_indicator)
	
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
		print("✅ División %s movida programáticamente a %s" % [data.nombre if data else "Desconocida", destino])
	else:
		print("❌ No se puede mover %s a la posición: %s" % [data.nombre if data else "Desconocida", destino])

func obtener_posicion() -> Vector2:
	"""Obtiene la posición actual de la división"""
	return global_position

func obtener_datos() -> DivisionData:
	"""Obtiene los datos de la división"""
	return data

func obtener_informacion_basica() -> Dictionary:
	"""Obtiene información básica de la división para mostrar en UI"""
	if not data:
		return {}
	
	return {
		"nombre": data.nombre,
		"faccion": data.faccion,
		"cantidad": data.cantidad_total,
		"moral": data.moral,
		"experiencia": data.experiencia,
		"movilidad": data.movilidad,
		"posicion": global_position
	}

func establecer_modo_accion(tipo_accion: String):
	"""Establece un modo de acción específico para la unidad"""
	match tipo_accion:
		"atacar":
			# Cambiar indicadores visuales para modo ataque
			if valid_area_indicator:
				valid_area_indicator.color = Color(1, 0, 0, 0.3)  # Rojo para ataque
			print("🗡️ Modo ataque activado para:", data.nombre)
		"fortificar":
			# Cambiar indicadores visuales para modo fortificación
			if valid_area_indicator:
				valid_area_indicator.color = Color(0.8, 0.8, 0, 0.3)  # Amarillo para fortificar
			print("🏰 Modo fortificación activado para:", data.nombre)
		"explorar":
			# Cambiar indicadores visuales para modo exploración
			if valid_area_indicator:
				valid_area_indicator.color = Color(0, 1, 0, 0.3)  # Verde para explorar
			print("🔍 Modo exploración activado para:", data.nombre)
		_:
			# Modo normal
			if valid_area_indicator:
				valid_area_indicator.color = Color(0, 0.8, 1, 0.3)  # Azul normal

func puede_realizar_accion(tipo_accion: String) -> bool:
	"""Verifica si la unidad puede realizar una acción específica"""
	if not data:
		return false
	
	match tipo_accion:
		"mover":
			return data.movilidad > 0
		"atacar":
			return data.moral > 30 and data.cantidad_total > 0
		"fortificar":
			return data.cantidad_total > 0
		"explorar":
			return data.movilidad > 0 and data.moral > 20
	
	return true

func obtener_rango_movimiento() -> float:
	"""Obtiene el rango de movimiento de la unidad basado en su movilidad"""
	if not data:
		return 100.0
	return data.movilidad * 50.0  # 50 píxeles por punto de movilidad

func actualizar_area_movimiento():
	"""Actualiza el área visual de movimiento válido"""
	if valid_area_indicator and data:
		var rango = obtener_rango_movimiento()
		valid_area_indicator.size = Vector2(rango * 2, rango * 2)
		valid_area_indicator.position = Vector2(-rango, -rango)

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
				
				# Mostrar indicadores visuales
				mostrar_indicadores_movimiento(true)
				
			else:
				# Fin del arrastre
				if is_dragging:
					is_dragging = false
					var nueva_posicion = global_position
					
					# Ocultar indicadores visuales
					mostrar_indicadores_movimiento(false)
					
					# Validar posición con el mapa estratégico
					if validar_movimiento_a_posicion(nueva_posicion):
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
		var nueva_pos = get_global_mouse_position() + drag_offset
		global_position = nueva_pos
		
		# Actualizar indicadores visuales
		actualizar_indicadores_movimiento()

func mostrar_indicadores_movimiento(mostrar: bool):
	"""Muestra u oculta los indicadores de movimiento"""
	if valid_area_indicator:
		valid_area_indicator.visible = mostrar
	if movement_indicator:
		movement_indicator.visible = mostrar
		if mostrar:
			movement_indicator.clear_points()
			movement_indicator.add_point(Vector2.ZERO)

func actualizar_indicadores_movimiento():
	"""Actualiza los indicadores visuales durante el movimiento"""
	if movement_indicator and movement_indicator.visible:
		# Actualizar línea de movimiento
		movement_indicator.clear_points()
		movement_indicator.add_point(original_position - global_position)
		movement_indicator.add_point(Vector2.ZERO)
		
		# Cambiar color según validez de la posición
		if validar_movimiento_a_posicion(global_position):
			movement_indicator.default_color = Color(0, 1, 0, 0.8)  # Verde
		else:
			movement_indicator.default_color = Color(1, 0, 0, 0.8)  # Rojo

func validar_posicion(posicion: Vector2) -> bool:
	"""Valida si la posición está dentro de los límites del mapa"""
	var strategic_map = get_tree().current_scene.get_node_or_null("StrategicMap")
	if not strategic_map:
		strategic_map = get_tree().current_scene
	
	if strategic_map and strategic_map.has_method("validar_posicion_unidad"):
		return strategic_map.validar_posicion_unidad(posicion, self)
	
	# Validación básica por defecto (límites amplios)
	return posicion.x > -2000 and posicion.x < 2000 and posicion.y > -2000 and posicion.y < 2000

func validar_movimiento_a_posicion(destino: Vector2) -> bool:
	"""Valida si se puede mover a una posición específica, incluyendo rango de movimiento"""
	if not validar_posicion(destino):
		return false
	
	# Verificar rango de movimiento
	var distancia = original_position.distance_to(destino)
	var rango_maximo = obtener_rango_movimiento()
	
	return distancia <= rango_maximo

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
		
		# Mostrar área de movimiento cuando está seleccionada
		if valid_area_indicator:
			actualizar_area_movimiento()  # Actualizar tamaño basado en movilidad
			valid_area_indicator.visible = true
			valid_area_indicator.color = Color(0, 0.8, 1, 0.3)  # Azul claro
	else:
		self.modulate = Color(1, 1, 1)   # Normal
		# Ocultar indicadores cuando no está seleccionada
		if valid_area_indicator:
			valid_area_indicator.visible = false
		if movement_indicator:
			movement_indicator.visible = false

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
