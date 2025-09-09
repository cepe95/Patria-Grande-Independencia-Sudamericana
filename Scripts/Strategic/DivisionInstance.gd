extends Control

signal division_seleccionada(division)

var data: DivisionData = null
var detail: DivisionData = null

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
	var tween := create_tween()
	tween.tween_property(self, "position", destino, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("✔ División clickeada:", data.nombre)
		emit_signal("division_seleccionada", self)
		resaltar_seleccion(true)

func resaltar_seleccion(activo: bool):
	if activo:
		self.modulate = Color(0.5, 0.5, 1) # Azul
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

func consumir_recursos_tick() -> void:
	"""Consume recursos por tick (llamado cada segundo)"""
	if not data:
		return
	
	var fac := FactionManager.obtener_faccion(data.faccion)
	if not fac:
		return

	if not data.unidades_componentes:
		return

	# Consumo base por tick para todas las unidades
	var consumo_base_pan = data.cantidad_total * 0.1  # 0.1 pan por soldado por tick
	var consumo_base_dinero = data.cantidad_total * 0.05  # 0.05 dinero por soldado por tick (mantenimiento)
	
	print("⚔️ %s consume recursos (soldados: %d)" % [data.nombre, data.cantidad_total])
	
	# Consumir recursos básicos
	if fac.recursos.has("pan"):
		fac.recursos["pan"] = max(0, fac.recursos["pan"] - consumo_base_pan)
	if fac.recursos.has("dinero"):
		fac.recursos["dinero"] = max(0, fac.recursos["dinero"] - consumo_base_dinero)
	
	# Consumo específico por tipo de unidad si están definidos
	for unidad in data.unidades_componentes:
		if not unidad or not unidad.consumo:
			continue
		for recurso in unidad.consumo.keys():
			var cantidad: float = unidad.consumo[recurso] * unidad.cantidad * 1.0  # 1 segundo
			if fac.recursos.has(recurso):
				fac.recursos[recurso] = max(0, fac.recursos[recurso] - cantidad)

func _process(delta: float) -> void:
	# Consumo de recursos movido al sistema de ticks para evitar consumo continuo
	# consumir_recursos(delta)
	pass
