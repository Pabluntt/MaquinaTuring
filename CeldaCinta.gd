extends Node3D

# ARRASTRA AQUÍ EL NODO QUE QUIERES QUE GIRE (Tu ficha completa)
@export var pieza_giratoria: Node3D 

# Configura aquí los ángulos (Prueba -90 o 90 si gira al revés)
var angulo_acostado = 0.0
var angulo_de_pie = -90.0 # Ajusta este número si queda chueca

func _ready():
	# Al iniciar, forzamos la posición visual según su grupo
	var cuerpo = encontrar_cuerpo_fisico()
	if cuerpo:
		if cuerpo.is_in_group("bit_1"):
			pieza_giratoria.rotation_degrees.z = angulo_de_pie
		else:
			pieza_giratoria.rotation_degrees.z = angulo_acostado

func convertirse_en_uno():
	print("ANIMANDO: Levantando ficha...")
	
	# 1. ANIMACIÓN SUAVE (TWEEN)
	var tween = create_tween()
	# Giramos en el eje X en 0.5 segundos
	tween.tween_property(pieza_giratoria, "rotation_degrees:z", angulo_de_pie, 0.5).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	
	# 2. LÓGICA (Cambio de Grupo)
	cambiar_grupo("bit_1")

func convertirse_en_cero():
	print("ANIMANDO: Acostando ficha...")
	
	# 1. ANIMACIÓN SUAVE
	var tween = create_tween()
	tween.tween_property(pieza_giratoria, "rotation_degrees:z", angulo_acostado, 0.5)
	
	# 2. LÓGICA
	cambiar_grupo("bit_0")

func cambiar_grupo(nuevo_grupo: String):
	var cuerpo = encontrar_cuerpo_fisico()
	if cuerpo:
		# Borramos grupos viejos para no confundir
		if cuerpo.is_in_group("bit_0"): cuerpo.remove_from_group("bit_0")
		if cuerpo.is_in_group("bit_1"): cuerpo.remove_from_group("bit_1")
		
		# Ponemos el nuevo
		cuerpo.add_to_group(nuevo_grupo)

func encontrar_cuerpo_fisico():
	# Busca el StaticBody dentro de la pieza giratoria
	for hijo in pieza_giratoria.get_children():
		if hijo is StaticBody3D: return hijo
	return null
