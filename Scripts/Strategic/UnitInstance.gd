extends CharacterBody2D

var data: UnitData
var destino: Vector2
var en_movimiento := false

@onready var sprite := $Sprite2D
@onready var label := $Label
func mover_a(pos: Vector2) -> void:
	destino = pos
	en_movimiento = true

func set_data(d: UnitData) -> void:
	data = d
	sprite.texture = d.icono
	label.text = "%s (%d)" % [data.nombre, data.cantidad]

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
