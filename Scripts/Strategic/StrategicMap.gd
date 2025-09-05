extends Node2D

var division := DivisionData.new()   # Podés borrar esta si no la usás más
const DivisionInstance = preload("res://Scenes/Strategic/DivisionInstance.tscn")
var unidad := UnitData.new()

@onready var units_container := $UnitsContainer
@onready var camera := $Camera2D

var zoom_min := 0.5
var zoom_max := 2.0
var move_speed := 300.0
var edge_margin := 20
var zoom_speed := 0.1
var division_seleccionada = null

func set_division_seleccionada(nueva):
	if division_seleccionada:
		division_seleccionada.resaltar_seleccion(false)
	division_seleccionada = nueva
	if division_seleccionada:
		division_seleccionada.resaltar_seleccion(true)
		print("✅ División seleccionada:", division_seleccionada.data.nombre)

func _ready():
	# Crear división patriota
	var patriota_division_1 := DivisionData.new()
	patriota_division_1.nombre = "División Leal a la Unión del Plata"
	patriota_division_1.rama_principal = "infantería"
	patriota_division_1.faccion = "Patriota"
	patriota_division_1.unidades_componentes = [
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Pelotón.tres"),
		preload("res://Data/Units/Caballería/Regimiento.tres")
	]
	patriota_division_1.cantidad_total = 300
	patriota_division_1.movilidad = 4
	patriota_division_1.moral = 85
	patriota_division_1.experiencia = 20
	patriota_division_1.icono_path = "res://Icons/Divisiones/patriota.png"

	# Crear división realista
	var realista_division_1 := DivisionData.new()
	realista_division_1.nombre = "División Realista de San Fernando"
	realista_division_1.rama_principal = "infantería"
	realista_division_1.faccion = "Realista"
	realista_division_1.unidades_componentes = [
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Caballería/Escuadrón.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Compañia.tres"),
		preload("res://Data/Units/Infantería/Pelotón.tres")
	]
	realista_division_1.cantidad_total = 320
	realista_division_1.movilidad = 3
	realista_division_1.moral = 90
	realista_division_1.experiencia = 25
	realista_division_1.icono_path = "res://Icons/Divisiones/realista.png"

	# Instanciar en el mapa
	instanciar_division(patriota_division_1, Vector2(-150, -350))
	instanciar_division(realista_division_1, Vector2(280, 350))

	# Límites de la cámara
	camera.limit_left = -2500
	camera.limit_top = -2500
	camera.limit_right = 2500
	camera.limit_bottom = 2500

func instanciar_division(data: DivisionData, posicion: Vector2) -> void:
	var instancia := DivisionInstance.instantiate()
	instancia.position = posicion
	units_container.add_child(instancia)
	instancia.set_button_data(data)

	# 🔌 Conectar señal de selección (Godot 4)
	instancia.connect("division_seleccionada", Callable(self, "_on_division_seleccionada"))

func _on_division_seleccionada(div_instancia):
	print("📡 Señal recibida de:", div_instancia.data.nombre)
	set_division_seleccionada(div_instancia)

# ⬇️ Función para instanciar mapas
func instance_map(info: Dictionary, _position: Vector2) -> Node2D:
	var mapa_scene := load(info.path)
	if not mapa_scene:
		push_error("⚠ No se pudo cargar el mapa desde: " + info.path)
		return null

	var mapa : Node2D = mapa_scene.instantiate()
	mapa.position = position
	mapa.set_meta("region", info.get("region", "desconocida"))
	mapa.set_meta("campaña", info.get("campaña", "sin definir"))

	return mapa

func _process(delta: float) -> void:
	var move := Vector2.ZERO
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_size := get_viewport().get_visible_rect().size

	# --- Movimiento con teclas ---
	if Input.is_action_pressed("ui_right"):
		move.x += 1
	if Input.is_action_pressed("ui_left"):
		move.x -= 1
	if Input.is_action_pressed("ui_down"):
		move.y += 1
	if Input.is_action_pressed("ui_up"):
		move.y -= 1

	# --- Movimiento con bordes de pantalla ---
	if mouse_pos.x <= edge_margin:
		move.x -= 1
	elif mouse_pos.x >= screen_size.x - edge_margin:
		move.x += 1

	if mouse_pos.y <= edge_margin:
		move.y -= 1
	elif mouse_pos.y >= screen_size.y - edge_margin:
		move.y += 1

	# Normalizar movimiento
	if move != Vector2.ZERO:
		move = move.normalized()

	camera.position += move * move_speed * delta

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Si clickeamos en "nada", deseleccionamos
		if not get_viewport().gui_get_focus_owner():
			if division_seleccionada:
				print("❌ Deseleccionando división:", division_seleccionada.data.nombre)
			set_division_seleccionada(null)

	# Ya tenías zoom acá
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_at_mouse(zoom_speed)  # acercar
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_at_mouse(-zoom_speed)  # alejar


func _zoom_at_mouse(amount: float) -> void:
	var old_zoom: Vector2 = camera.zoom
	var new_zoom: Vector2 = clamp(
		old_zoom + Vector2(amount, amount),
		Vector2(zoom_min, zoom_min),
		Vector2(zoom_max, zoom_max)
	)
	var mouse_pos := get_global_mouse_position()

	# Ajustar posición para que el zoom sea hacia el mouse
	var offset: Vector2 = (mouse_pos - camera.position) * (1.0 - new_zoom.x / old_zoom.x)

	camera.position += offset
	camera.zoom = new_zoom
