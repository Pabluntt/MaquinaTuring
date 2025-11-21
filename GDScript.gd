extends Node3D

# --- Variables de Configuración ---
@export var velocidad_ciclo: float = 0.5 # Segundos por cada paso de la máquina
@export var distancia_celda: float = 3.0 # Distancia que se mueve el cabezal por celda

# --- Variables de Estado Interno ---
var estado_actual: String = "q0" # Estado inicial
var indice_cabezal: int = 0      # Posición actual del cabezal en la cinta (0 es la primera celda)
var simbolo_leido: String = ""   # El símbolo que el cabezal acaba de leer

# --- La "Tabla de Estados" (el cerebro de la máquina) ---
var tabla_de_estados = {
	"q0": {
		"1": {"acciones": ["mover_derecha"], "siguiente_estado": "q0"},
		"X": {"acciones": ["escribir_1", "mover_derecha"], "siguiente_estado": "q1"},
		"[]": {"acciones": ["halt"], "siguiente_estado": "q0"} # Por defecto, se queda en q0 si hay halt
	},
	"q1": {
		"1": {"acciones": ["mover_derecha"], "siguiente_estado": "q1"},
		"X": {"acciones": ["mover_izquierda"], "siguiente_estado": "q2"},
		"[]": {"acciones": ["mover_izquierda"], "siguiente_estado": "q2"}
	},
	"q2": {
		"1": {"acciones": ["escribir_vacio"], "siguiente_estado": "q2"}, # Corrige esta acción a la de tu plano
		"X": {"acciones": ["mover_izquierda"], "siguiente_estado": "q2"},
		"[]": {"acciones": ["halt"], "siguiente_estado": "q2"}
	}
	# !!!!!!!!! IMPORTANTE: Ajusta esta tabla con tus planos de SUMA y RESTA !!!!!!!!!
	# ¡Los 'siguiente_estado' deben reflejar tus 'Saltar a qX'!
}

func _process(delta: float) -> void:
	pass
