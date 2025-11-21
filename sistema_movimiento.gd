extends Node3D

# Referencia al nodo pivote que tiene todas las piezas giratorias de la manivela.
# Asegúrate de que esta ruta sea correcta: SistemaMovimiento/ejeLógico
@onready var eje_manivela = $ejeLógico 

# Referencia al nodo del cabezal.
# Asegúrate de que esta ruta sea correcta: SistemaMovimiento/Cabezal
@onready var cabezal = $Cabezal 

# ---------- CONFIGURACIÓN DE MOVIMIENTO ----------
# Velocidad a la que gira la manivela cuando la mueves con las teclas.
var velocidad_rotacion_manivela = 270.0 # Grados por segundo. Aumenta o disminuye para que vaya más rápido/lento.

# Cuántos METROS (unidades de Godot) avanza el cabezal por cada 360 grados (1 vuelta) de la manivela.
# Ajusta este valor para que el cabezal avance a una velocidad visualmente coherente con la manivela/cadena.
# Por ejemplo, si una vuelta de manivela mueve la cadena un metro, pon 1.0.
var avance_cabezal_por_vuelta_manivela = 3.0 # Esto es crucial para la sincronización.

# Variable para almacenar la rotación total acumulada del eje de la manivela.
# Esto nos permite saber cuántas "vueltas" ha dado la manivela.
var rotacion_total_manivela = 0.0

func _process(delta):
	var rotacion_este_frame = 0.0 # Cuántos grados rotará la manivela en este frame

	# Detectar la pulsación de teclas para girar la manivela
	if Input.is_action_pressed("ui_right"):
		rotacion_este_frame = velocidad_rotacion_manivela * delta
	elif Input.is_action_pressed("ui_left"):
		rotacion_este_frame = -velocidad_rotacion_manivela * delta
		
	if rotacion_este_frame != 0.0:
		# 1. Girar la Manivela (Visual)
		# Suponiendo que tu manivela gira en el eje X local. Si es Z, cambia 'rotate_x' por 'rotate_z'.
		eje_manivela.rotate_x(deg_to_rad(rotacion_este_frame))
		
		# Acumular la rotación para saber el total (útil para el cabezal)
		rotacion_total_manivela += rotacion_este_frame
		
		# 2. Mover el Cabezal (Lineal)
		# Calculamos el desplazamiento lineal del cabezal.
		# Convertimos los grados de rotación de este frame a un porcentaje de una vuelta (grados / 360)
		# y luego lo multiplicamos por el avance total por vuelta.
		var desplazamiento_lineal_cabezal = (rotacion_este_frame / 360.0) * avance_cabezal_por_vuelta_manivela
		
		# Mueve el cabezal en el eje X. Si tu cabezal se mueve en el eje Z, cambia 'position.x' a 'position.z'.
		cabezal.position.z += desplazamiento_lineal_cabezal
