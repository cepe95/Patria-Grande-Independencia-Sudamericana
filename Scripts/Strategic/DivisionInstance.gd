extends Control

var data: DivisionData = null
var detail: DivisionData = null

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var label: Label = get_node_or_null("Label")
@onready var icon: TextureRect = get_node_or_null("DivisionInstance/Icon") # Debe ser un TextureRect

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

func set_data(d: DivisionData):
	if not d:
		push_error("⚠ Se intentó asignar un 'data' nulo en set_data()")
		return
	
	data = d
	if sprite and d.icono:
		sprite.texture = d.icono
	if label:
		label.text = "%s (%d)" % [d.nombre, d.cantidad_total]

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

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if get_tree().current_scene.has_method("division_seleccionada"):
			get_tree().current_scene.division_seleccionada = self

func obtener_area_visual() -> Rect2:
	if sprite and sprite.texture:
		return Rect2(global_position - sprite.texture.get_size() / 2, sprite.texture.get_size())
	return Rect2(global_position, Vector2.ZERO)

func consumir_recursos(delta: float) -> void:
	if not data:
		# Evita crashear si no se inicializó la división
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
