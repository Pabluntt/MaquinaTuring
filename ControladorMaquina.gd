extends Node3D

# ==========================================
# 1. REFERENCIAS
# ==========================================
# --- SELECCIÓN DE MODO ---
enum ModoOperacion { SUMA, RESTA }
@export var modo_actual: ModoOperacion = ModoOperacion.SUMA 

@export_category("--- Modelos de Cilindros ---")
@export var modelo_cilindro_suma: Node3D
@export var modelo_cilindro_resta: Node3D

@export_category("--- Referencias Físicas ---")
@export var eje_manivela: Node3D
@export var cabezal: Node3D
@export var cilindro_principal: Node3D

@export_category("--- Sensores (TODO RAYCASTS) ---")
@export var raycast_verde_frente: RayCast3D 
@export var raycast_verde_abajo: RayCast3D
@export var raycast_amarillo_izq: RayCast3D
@export var contenedor_fichas: Node3D
@export var raycast_amarillo_der: RayCast3D 

@export_category("--- Músculos Visuales ---")
@export var visual_verde_1: Node3D    
@export var visual_verde_0: Node3D    
@export var visual_amarillo_izq: Node3D
@export var visual_amarillo_der: Node3D

# ==========================================
# 2. VARIABLES
# ==========================================
var velocidad_rotacion_manivela = 270.0 
var avance_por_vuelta = 3.0  
var rotacion_acumulada: float = 0.0
var direccion_actual: int = 1 
var estado_actual: String = "q0"
var angulo_base_estado: float = 0.0
var tabla_activa = {} 

# --- TABLAS DE LÓGICA ---
var tabla_suma = {
	"q0": { "UNO": {"escribir": "1", "mover": "R", "prox_estado": "q0"}, "CERO": {"escribir": "1", "mover": "R", "prox_estado": "q1"}, "FIN": {"escribir": "[]", "mover": "L", "prox_estado": "HALT"} },
	"q1": { "UNO": {"escribir": "1", "mover": "R", "prox_estado": "q1"}, "CERO": {"escribir": "0", "mover": "L", "prox_estado": "q2"}, "FIN": {"escribir": "[]", "mover": "L", "prox_estado": "q2"} },
	"q2": { "UNO": {"escribir": "0", "mover": "HALT", "prox_estado": "HALT"}, "CERO": {"escribir": "0", "mover": "HALT", "prox_estado": "HALT"}, "NADA": {"escribir": "0", "mover": "HALT", "prox_estado": "HALT"}, "FIN": {"escribir": "[]", "mover": "HALT", "prox_estado": "HALT"} }
}

var tabla_resta = {
	"q0": { "UNO": {"escribir": "1", "mover": "R", "prox_estado": "q0"}, "CERO": {"escribir": "0", "mover": "R", "prox_estado": "q1"}, "FIN": {"escribir": "[]", "mover": "L", "prox_estado": "HALT"} },
	"q1": { "UNO": {"escribir": "0", "mover": "L", "prox_estado": "q2"}, "CERO": {"escribir": "0", "mover": "R", "prox_estado": "q1"}, "FIN": {"escribir": "[]", "mover": "HALT", "prox_estado": "HALT"} },
	"q2": { "UNO": {"escribir": "0", "mover": "R", "prox_estado": "q1"}, "CERO": {"escribir": "0", "mover": "L", "prox_estado": "q2"}, "FIN": {"escribir": "[]", "mover": "HALT", "prox_estado": "HALT"} }
}

func _ready():
	# Alineación inicial
	rotacion_acumulada = 0.0
	eje_manivela.rotation_degrees.x = 0.0
	
	# --- INTERRUPTOR DE LÓGICA Y VISUAL ---
	if modo_actual == ModoOperacion.SUMA:
		print(">> MODO: SUMA (Cargando tabla y modelo...)")
		tabla_activa = tabla_suma
		
		
		if modelo_cilindro_suma: modelo_cilindro_suma.visible = true
		if modelo_cilindro_resta: modelo_cilindro_resta.visible = false
		
	else:
		print(">> MODO: RESTA (Cargando tabla y modelo...)")
		tabla_activa = tabla_resta
		
		
		if modelo_cilindro_suma: modelo_cilindro_suma.visible = false
		if modelo_cilindro_resta: modelo_cilindro_resta.visible = true

func _process(delta):
	if Input.is_action_pressed("ui_right"):
		procesar_avance_mecanico(delta)
	
	
	verificar_choque_topes() 
	
	animar_cilindro_y_palancas(delta)

# --- MOVIMIENTO ---
func procesar_avance_mecanico(delta):
	var multiplicador = 1.0
	if Input.is_key_pressed(KEY_SHIFT): multiplicador = 5.0 
	
	var giro_frame = (velocidad_rotacion_manivela * multiplicador) * delta
	eje_manivela.rotate_x(deg_to_rad(-giro_frame)) 
	
	rotacion_acumulada += giro_frame
	var desplazamiento = (giro_frame / 360.0) * avance_por_vuelta
	cabezal.position.z -= desplazamiento * direccion_actual 
	
	if rotacion_acumulada >= 360.0:
		rotacion_acumulada -= 360.0
		ejecutar_ciclo_cerebro()

# --- MONITOR DE CHOQUES (RAYCAST PURO) ---
var cooldown_choque: float = 0.0

func verificar_choque_topes():
	if cooldown_choque > 0:
		cooldown_choque -= get_process_delta_time()
		return

	# 1. Obligamos a mirar YA
	raycast_amarillo_izq.force_raycast_update()
	raycast_amarillo_der.force_raycast_update() 
	
	var tipo_choque = "NADA"
	
	# 2. Detección Direccional
	if direccion_actual == 1 and raycast_amarillo_der.is_colliding():
		if raycast_amarillo_der.get_collider().is_in_group("bit_vacio"):
			tipo_choque = "FIN_DER"
			
	elif direccion_actual == -1 and raycast_amarillo_izq.is_colliding():
		if raycast_amarillo_izq.get_collider().is_in_group("bit_vacio"):
			tipo_choque = "FIN_IZQ"
	
	# 3. Reacción
	if tipo_choque != "NADA":
		print(">> ¡CHOQUE DETECTADO (", tipo_choque, ")!")
		
		
		var celda_actual = round(cabezal.position.z / avance_por_vuelta)
		cabezal.position.z = celda_actual * avance_por_vuelta
		
		
		ejecutar_logica_por_choque("FIN")
		rotacion_acumulada = 0.0
		cooldown_choque = 0.5

func ejecutar_ciclo_cerebro():
	print(">> CICLO COMPLETO...")
	var lectura = obtener_lectura_forzada()
	procesar_decision(lectura)

func ejecutar_logica_por_choque(lectura_forzada: String):
	print("   Procesando choque como: ", lectura_forzada)
	procesar_decision(lectura_forzada)

func procesar_decision(lectura: String):
	print("   Estado: ", estado_actual, " | Viendo: ", lectura)
	if tabla_activa.has(estado_actual):
		var estado_datos = tabla_activa[estado_actual]
		var clave = lectura
		if clave == "FIN_IZQ" or clave == "FIN_DER": clave = "FIN"
		
		if estado_datos.has(clave):
			var orden = estado_datos[clave]
			print("   ORDEN: ", orden)
			modificar_cinta(orden["escribir"])
			
			if orden["mover"] == "R": direccion_actual = 1
			elif orden["mover"] == "L": direccion_actual = -1
			elif orden["mover"] == "HALT": direccion_actual = 0
				
			estado_actual = orden["prox_estado"]
			actualizar_angulo_cilindro()
			configurar_animacion_palancas(clave)

# --- LECTURA Y UTILIDADES ---
func obtener_lectura_forzada() -> String:
	raycast_verde_frente.force_raycast_update()
	raycast_verde_abajo.force_raycast_update()
	raycast_amarillo_izq.force_raycast_update()
	raycast_amarillo_der.force_raycast_update()
	
	if raycast_amarillo_izq.is_colliding() and raycast_amarillo_izq.get_collider().is_in_group("bit_vacio"): return "FIN_IZQ"
	if raycast_amarillo_der.is_colliding() and raycast_amarillo_der.get_collider().is_in_group("bit_vacio"): return "FIN_DER"
	
	if raycast_verde_frente.is_colliding():
		var col = raycast_verde_frente.get_collider()
		if col.is_in_group("bit_1") or col.get_parent().is_in_group("bit_1"): return "UNO"
		
	if raycast_verde_abajo.is_colliding():
		var col = raycast_verde_abajo.get_collider()
		if col.is_in_group("bit_0") or col.get_parent().is_in_group("bit_0"): return "CERO"
		if col.is_in_group("bit_1") or col.get_parent().is_in_group("bit_1"): return "UNO"

	return "NADA"

func modificar_cinta(valor: String):
	var target = null
	
	
	if raycast_verde_abajo.is_colliding(): target = raycast_verde_abajo.get_collider()
	elif raycast_verde_frente.is_colliding(): target = raycast_verde_frente.get_collider()
	
	
	if target:
		
		var nodo = target
		for i in range(4):
			if nodo == null: break
			if nodo.has_method("convertirse_en_uno"): 
				target = nodo 
				break
			nodo = nodo.get_parent()
			
		
		if not target.has_method("convertirse_en_uno"): target = null

	
	if target == null and contenedor_fichas != null:
		print(">> FÍSICA FALLÓ. USANDO GPS PARA ENCONTRAR FICHA...")
		
		var distancia_minima = 999.0
		var ficha_mas_cercana = null
		
		
		for ficha in contenedor_fichas.get_children():
			
			var dist = abs(ficha.global_position.z - cabezal.global_position.z)
			
			
			if dist < 2.0 and dist < distancia_minima:
				distancia_minima = dist
				ficha_mas_cercana = ficha
		
		
		if ficha_mas_cercana and ficha_mas_cercana.has_method("convertirse_en_uno"):
			target = ficha_mas_cercana
			print(">> GPS ENCONTRÓ: ", target.name, " a ", distancia_minima, "m")

	
	if target and target.has_method("convertirse_en_uno"):
		print(">> ¡ÉXITO! Modificando cinta a: ", valor)
		if valor == "1": target.convertirse_en_uno()
		elif valor == "0": target.convertirse_en_cero()
	else:
		print("ERROR FATAL: No hay ficha ni por RayCast ni por GPS. Revisa la referencia 'contenedor_fichas'.")

# --- ANIMACIÓN ---
var target_cilindro = 0.0
var t_v1=0.0; var t_v0=0.0; var t_ami=0.0; var t_amd=0.0

func actualizar_angulo_cilindro():
	match estado_actual:
		"q0": target_cilindro = 0.0
		"q1": target_cilindro = 120.0
		"q2": target_cilindro = 240.0

func configurar_animacion_palancas(tipo: String):
	t_v1=0.0; t_v0=0.0; t_ami=0.0; t_amd=0.0
	match tipo:
		"CERO": t_v0 = -25.0
		"UNO": t_v1 = -25.0
		"FIN", "FIN_IZQ": t_ami = -25.0
		"FIN_DER": t_amd = -25.0

func animar_cilindro_y_palancas(delta):
	var offset_lectura = 0.0
	
	if raycast_amarillo_izq.is_colliding() or raycast_amarillo_der.is_colliding(): offset_lectura = 20.0
	elif raycast_verde_frente.is_colliding(): offset_lectura = 10.0
	
	var angulo_final_total = target_cilindro + offset_lectura
	cilindro_principal.rotation_degrees.z = lerp(cilindro_principal.rotation_degrees.z, angulo_final_total, delta * 5)
	
	visual_verde_1.rotation_degrees.x = lerp(visual_verde_1.rotation_degrees.x, t_v1, delta * 10)
	visual_verde_0.rotation_degrees.x = lerp(visual_verde_0.rotation_degrees.x, t_v0, delta * 10)
	visual_amarillo_izq.rotation_degrees.x = lerp(visual_amarillo_izq.rotation_degrees.x, t_ami, delta * 10)
	visual_amarillo_der.rotation_degrees.x = lerp(visual_amarillo_der.rotation_degrees.x, t_amd, delta * 10)
