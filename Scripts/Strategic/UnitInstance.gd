extends CharacterBody2D

var data: UnitData
var destino: Vector2
var en_movimiento := false
var is_selected := false

@onready var sprite := $Sprite2D
@onready var label := $Label

# Selection visual properties
var original_modulate: Color
var selection_outline: Node2D

func _ready():
	original_modulate = modulate

func mover_a(pos: Vector2) -> void:
	destino = pos
	en_movimiento = true

# New method for SelectionManager integration
func move_to(pos: Vector2) -> void:
	mover_a(pos)

func set_data(d: UnitData) -> void:
	data = d
	sprite.texture = d.icono
	label.text = "%s (%d)" % [data.nombre, data.cantidad]

# Add selection support for SelectionManager
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_selection_visual()

func _update_selection_visual() -> void:
	if is_selected:
		modulate = Color(0.3, 0.8, 1.0, 1.0)  # Light blue tint
		# Add outline effect if possible
		_add_selection_outline()
	else:
		modulate = original_modulate
		_remove_selection_outline()

func _add_selection_outline() -> void:
	if selection_outline:
		return
	
	# Create a simple outline effect by adding a slightly larger sprite behind
	selection_outline = Sprite2D.new()
	selection_outline.texture = sprite.texture
	selection_outline.modulate = Color(1.0, 1.0, 1.0, 0.8)  # White outline
	selection_outline.scale = sprite.scale * 1.1  # Slightly larger
	selection_outline.z_index = sprite.z_index - 1
	add_child(selection_outline)
	move_child(selection_outline, 0)  # Move to back

func _remove_selection_outline() -> void:
	if selection_outline:
		selection_outline.queue_free()
		selection_outline = null

# Method to check if unit belongs to player (for selection filtering)
func is_player_unit() -> bool:
	if data and data.has("faccion"):
		return data.faccion == "Patriota"
	return true  # Default to selectable for now

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		descomponer()

func descomponer() -> void:
	var subunidades := generar_subunidades(data)
	if subunidades.is_empty():
		return

	for sub_data in subunidades:
		var instancia := preload("res://scenes/strategic/UnitInstance.tscn").instantiate()
		instancia.set_data(sub_data)
		get_tree().current_scene.add_child(instancia)

	queue_free()

func _process(delta: float) -> void:
	if en_movimiento:
		var distancia := position.distance_to(destino)
		if distancia > 1:
			var direccion := (destino - position).normalized()
			position += direccion * data.velocidad * delta
		else:
			position = destino
			en_movimiento = false

# Improved area detection for selection
func obtener_area_visual() -> Rect2:
	if sprite and sprite.texture:
		var size = sprite.texture.get_size() * sprite.scale
		return Rect2(global_position - size / 2, size)
	return Rect2(global_position - Vector2(25, 25), Vector2(50, 50))

func generar_subunidades(data: UnitData) -> Array:
	var resultado := []
	var tipo: String = data.tipo.capitalize()
	var cantidad: int = data.cantidad
	var nivel: int = data.nivel

	match nivel:
		4:  # Regimiento → 3 Compañías
			for i in range(3):
				var sub := UnitData.new()
				sub.tipo = data.tipo
				sub.nivel = 2
				sub.cantidad = int(cantidad / 3)
				sub.nombre = "%s Compañía %d" % [tipo, i + 1]
				var ruta := "res://assets/icons/Compañía %s.png" % tipo
				var textura := load(ruta)
				if textura:
					sub.icono = textura
				resultado.append(sub)
		3:  # Batallón → 2 Compañías
			for i in range(2):
				var sub := UnitData.new()
				sub.tipo = data.tipo
				sub.nivel = 2
				sub.cantidad = int(cantidad / 2)
				sub.nombre = "%s Compañía %d" % [tipo, i + 1]
				var ruta := "res://assets/icons/Compañía %s.png" % tipo
				var textura := load(ruta)
				if textura:
					sub.icono = textura
				resultado.append(sub)
		2:  # Compañía → 3 Pelotones
			for i in range(3):
				var sub := UnitData.new()
				sub.tipo = data.tipo
				sub.nivel = 1
				sub.cantidad = int(cantidad / 3)
				sub.nombre = "%s Pelotón %d" % [tipo, i + 1]
				var ruta := "res://assets/icons/Pelotón %s.png" % tipo
				var textura := load(ruta)
				if textura:
					sub.icono = textura
				resultado.append(sub)
		_:  # Nivel más bajo, no se descompone
			pass
	return resultado
