"""Efectos de sonido de Kalin: interfaz, aciertos, libro, exploración e historia.

Cada función devuelve audio mono o estéreo; `generar.py` lo normaliza y lo
guarda con su nombre en español. Todos se sintetizan desde cero.
"""
from __future__ import annotations

import math

import numpy as np

import sintesis as s

# ─── Herramientas ────────────────────────────────────────────────────────────

def lienzo(duracion: float) -> np.ndarray:
	return np.zeros(s.segundos(duracion))


def poner(destino: np.ndarray, inicio: float, x: np.ndarray, vol: float = 1.0) -> None:
	i = s.segundos(inicio)
	fin = min(i + len(x), len(destino))
	if fin > i:
		destino[i:fin] += x[: fin - i] * vol


def tono(f: float, dur: float, t60: float, armonicos=((1, 1.0),), ataque_ms: float = 2.0) -> np.ndarray:
	n = s.segundos(dur)
	t = s.tiempo(n)
	x = sum(a * np.sin(2 * np.pi * f * k * t) for k, a in armonicos)
	return s.ataque_suave(x * s.decaimiento(n, t60), ataque_ms)


def barrido(f0: float, f1: float, dur: float, curva: float = 1.0) -> np.ndarray:
	"""Seno que glisa de f0 a f1 (curva > 1 acelera al final)."""
	n = s.segundos(dur)
	p = np.linspace(0.0, 1.0, n) ** curva
	f = f0 * (f1 / f0) ** p
	return np.sin(2 * np.pi * np.cumsum(f) / s.SR)


def banda_variable(x: np.ndarray, f0: float, f1: float, q: float = 1.2) -> np.ndarray:
	"""Filtro de estado variable con frecuencia central que va de f0 a f1."""
	n = len(x)
	fc = f0 * (f1 / f0) ** np.linspace(0.0, 1.0, n)
	g = np.tan(np.pi * np.minimum(fc, s.SR * 0.45) / s.SR)
	k = 1.0 / q
	salida = np.zeros(n)
	ic1 = ic2 = 0.0
	for i in range(n):
		gi = g[i]
		a1 = 1.0 / (1.0 + gi * (gi + k))
		v3 = x[i] - ic2
		v1 = a1 * ic1 + gi * a1 * v3
		v2 = ic2 + gi * v1
		ic1 = 2.0 * v1 - ic1
		ic2 = 2.0 * v2 - ic2
		salida[i] = v1
	return salida


def soplido(dur: float, f0: float, f1: float, semilla: int = 1, q: float = 1.5) -> np.ndarray:
	"""Ráfaga de aire que sube o baja de tono."""
	n = s.segundos(dur)
	x = banda_variable(s.ruido(n, semilla), f0, f1, q)
	env = np.sin(np.linspace(0, np.pi, n)) ** 1.5
	return x * env


def papel(dur: float, semilla: int = 1, brillo: float = 1.0) -> np.ndarray:
	"""Roce de papel: ruido con chasquidos irregulares."""
	n = s.segundos(dur)
	rng = np.random.default_rng(semilla)
	crujido = np.repeat(rng.uniform(0.2, 1.0, n // 200 + 1), 200)[:n]
	crujido *= (rng.random(n) < 0.35) * 0.6 + 0.4
	x = s.filtro(s.ruido(n, semilla) * crujido, "band", [900.0, 5000.0 + 4000.0 * brillo])
	env = np.sin(np.linspace(0, np.pi, n)) ** 0.8
	return x * env


def chispas(dur: float, cantidad: int, f_min: float = 2000.0, f_max: float = 5200.0, semilla: int = 5) -> np.ndarray:
	"""Campanitas agudas al azar dentro de una escala pentatónica."""
	rng = np.random.default_rng(semilla)
	x = lienzo(dur + 1.2)
	pentatonica = [0, 2, 4, 7, 9]
	base = 12 * math.log2(f_min / 440.0) + 69
	tope = 12 * math.log2(f_max / 440.0) + 69
	for _ in range(cantidad):
		midi = rng.uniform(base, tope)
		midi = round(midi) - (round(midi) % 12) + pentatonica[rng.integers(0, 5)]
		poner(x, rng.uniform(0, dur), s.campana(round(s.midi_a_hz(midi), 2), 0.3, 0.6), rng.uniform(0.25, 0.7))
	return x


def nota(n: str) -> float:
	return s.frecuencia(n)


def golpe_madera(f: float, vel: float = 1.0) -> np.ndarray:
	return s.caparazon(f, vel)


# ─── Interfaz ────────────────────────────────────────────────────────────────

def boton_clic() -> np.ndarray:
	x = lienzo(0.12)
	poner(x, 0.0, tono(1320.0, 0.1, 0.035, ((1, 1.0), (2.4, 0.4))))
	poner(x, 0.0, s.filtro(s.ruido(s.segundos(0.006), 2), "high", 3000.0), 0.3)
	return x


def boton_pasar() -> np.ndarray:
	return tono(2350.0, 0.06, 0.02, ((1, 1.0), (2, 0.2)), 1.0)


def panel_abrir() -> np.ndarray:
	x = lienzo(0.55)
	poner(x, 0.0, soplido(0.28, 500.0, 3500.0, 3), 0.5)
	poner(x, 0.06, s.marimba(nota("A5"), 0.2, 0.6))
	poner(x, 0.13, s.marimba(nota("E6"), 0.3, 0.7))
	return x


def panel_cerrar() -> np.ndarray:
	x = lienzo(0.5)
	poner(x, 0.0, soplido(0.25, 3000.0, 500.0, 4), 0.45)
	poner(x, 0.02, s.marimba(nota("E6"), 0.2, 0.55))
	poner(x, 0.09, s.marimba(nota("A5"), 0.3, 0.6))
	return x


def pausa_abrir() -> np.ndarray:
	x = lienzo(1.0)
	for i, n in enumerate(["D6", "A5", "F#5"]):
		poner(x, i * 0.09, s.marimba(nota(n), 0.4, 0.65))
	poner(x, 0.0, s.colchon(nota("D4"), 0.5, 0.6, 0.2), 0.8)
	return x


def pausa_cerrar() -> np.ndarray:
	x = lienzo(0.8)
	for i, n in enumerate(["F#5", "A5", "D6"]):
		poner(x, i * 0.07, s.marimba(nota(n), 0.4, 0.65))
	return x


def mapa_seleccionar() -> np.ndarray:
	x = lienzo(0.8)
	poner(x, 0.0, s.tunkul(147.0, 0.7))
	poner(x, 0.04, s.marimba(nota("D6"), 0.3, 0.6))
	poner(x, 0.1, s.campana(nota("A6"), 0.3, 0.5))
	return x


# ─── Aciertos y progreso ────────────────────────────────────────────────────

def acierto() -> np.ndarray:
	x = lienzo(1.1)
	for i, n in enumerate(["D6", "F#6", "A6"]):
		poner(x, i * 0.065, s.marimba(nota(n), 0.3, 0.8))
	poner(x, 0.2, s.campana(nota("D7"), 0.5, 0.6))
	poner(x, 0.18, chispas(0.35, 4, 3500, 6000, 9), 0.5)
	return x


def error_suave() -> np.ndarray:
	"""Equivocarse no castiga: dos notas de madera que bajan, con calma."""
	x = lienzo(0.75)
	poner(x, 0.0, s.marimba(nota("E4"), 0.15, 0.7))
	poner(x, 0.16, s.marimba(nota("C4"), 0.25, 0.65))
	poner(x, 0.0, s.tunkul(95.0, 0.4))
	return s.filtro(x, "low", 2600.0)


def palabra_aprendida() -> np.ndarray:
	x = lienzo(2.2)
	for i, n in enumerate(["D5", "E5", "F#5", "A5", "B5", "D6"]):
		poner(x, i * 0.07, s.campana(nota(n), 0.5, 0.55))
	poner(x, 0.42, s.campana(nota("A6"), 0.8, 0.6))
	poner(x, 0.0, papel(0.35, 7), 0.25)
	poner(x, 0.3, chispas(0.7, 9, 3000, 7000, 11), 0.45)
	return x


def nivel_completado() -> np.ndarray:
	"""Fanfarria corta: marimba, clarinete y flauta con redoble final (Re mayor)."""
	x = lienzo(4.2)
	frase = [("D5", 0.0, 0.18), ("F#5", 0.2, 0.18), ("A5", 0.4, 0.18), ("D6", 0.6, 0.5), ("B5", 1.15, 0.18), ("D6", 1.35, 0.18), ("E6", 1.55, 0.25)]
	for n, t, d in frase:
		poner(x, t, s.clarinete(nota(n), d, 0.8), 0.9)
		poner(x, t, s.marimba(nota(n), d, 0.8), 0.8)
	for i in range(int(1.6 * 13)):
		v = 0.45 + 0.35 * i / 20
		for n in ("D6", "F#6", "A6"):
			poner(x, 1.85 + i / 13, s.marimba(nota(n), 0.1, min(v, 0.8)), 0.45)
	for n in ("D5", "F#5", "A5", "D6"):
		poner(x, 1.85, s.flauta(nota(n), 1.6, 0.6), 0.5)
	poner(x, 1.85, s.bajo(nota("D3"), 1.6, 0.9), 0.9)
	poner(x, 1.85, s.tunkul(110.0, 0.9))
	poner(x, 3.45, s.tunkul(110.0, 1.0))
	poner(x, 3.45, chispas(0.5, 8, 3000, 7000, 13), 0.6)
	for t in np.arange(0, 1.8, 0.2):
		poner(x, t, s.sonaja(0.5, 0.08, int(t * 10) + 1), 0.6)
	return x


def mision_pausa() -> np.ndarray:
	x = lienzo(1.4)
	poner(x, 0.0, papel(0.3, 31), 0.4)
	poner(x, 0.1, s.campana(nota("A5"), 0.5, 0.6))
	poner(x, 0.28, s.campana(nota("D6"), 0.6, 0.6))
	return x


# ─── Libro de hechizos ──────────────────────────────────────────────────────

def libro_abrir() -> np.ndarray:
	x = lienzo(1.4)
	poner(x, 0.0, s.tambor(150.0, 0.35), 0.6)
	poner(x, 0.02, papel(0.45, 41), 0.8)
	poner(x, 0.25, s.campana(nota("A5"), 0.6, 0.5), 0.8)
	poner(x, 0.33, s.campana(nota("E6"), 0.6, 0.5), 0.8)
	return x


def libro_cerrar() -> np.ndarray:
	x = lienzo(0.6)
	poner(x, 0.0, papel(0.18, 43, 0.6), 0.6)
	poner(x, 0.15, s.tambor(120.0, 0.6))
	poner(x, 0.15, s.filtro(s.ruido(s.segundos(0.05), 44), "low", 1200.0) * np.linspace(1, 0, s.segundos(0.05)), 0.5)
	return x


def pagina_pasar() -> np.ndarray:
	x = lienzo(0.4)
	poner(x, 0.0, papel(0.3, 51))
	poner(x, 0.0, soplido(0.3, 1500.0, 4500.0, 52), 0.25)
	return x


def pagina_recuperada() -> np.ndarray:
	x = lienzo(2.0)
	for i in range(4):
		poner(x, i * 0.12, papel(0.25, 60 + i), 0.5)
	for i, n in enumerate(["A5", "D6", "F#6", "A6"]):
		poner(x, 0.3 + i * 0.09, s.campana(nota(n), 0.6, 0.6))
	poner(x, 0.6, chispas(0.7, 10, 3000, 7000, 61), 0.5)
	return x


# ─── Exploración ─────────────────────────────────────────────────────────────

def paso(superficie: str, variante: int) -> np.ndarray:
	"""Un paso de Kalin sobre arena, tierra, pasto o piedra (sascab)."""
	rng = np.random.default_rng(100 + variante + 10 * ("arena", "tierra", "pasto", "piedra").index(superficie))
	dur = 0.16 + rng.uniform(0, 0.04)
	n = s.segundos(dur)
	t = s.tiempo(n)
	x = np.zeros(n)
	if superficie == "arena":
		granos = s.ruido(n, 200 + variante) * (rng.random(n) < 0.25)
		x += s.filtro(granos, "band", [700.0, 4000.0]) * np.exp(-t / 0.06) * 1.2
		x += np.sin(2 * np.pi * 90 * t) * np.exp(-t / 0.03) * 0.3
	elif superficie == "tierra":
		x += np.sin(2 * np.pi * (110 + 15 * variante) * t) * np.exp(-t / 0.035) * 0.9
		x += s.filtro(s.ruido(n, 210 + variante), "low", 1500.0) * np.exp(-t / 0.03) * 0.7
	elif superficie == "pasto":
		x += s.filtro(s.ruido(n, 220 + variante) * (rng.random(n) < 0.5), "band", [1800.0, 8000.0]) * np.sin(np.linspace(0, np.pi, n)) * 0.9
		x += np.sin(2 * np.pi * 95 * t) * np.exp(-t / 0.025) * 0.35
	else:  # piedra
		x += np.sin(2 * np.pi * (1700 + 120 * variante) * t) * np.exp(-t / 0.012) * 0.35
		x += np.sin(2 * np.pi * 130 * t) * np.exp(-t / 0.03) * 0.7
		x += s.filtro(s.ruido(n, 230 + variante), "band", [600.0, 3000.0]) * np.exp(-t / 0.02) * 0.6
	return s.final_suave(s.ataque_suave(x, 1.0))


def examinar_objeto() -> np.ndarray:
	x = lienzo(0.9)
	poner(x, 0.0, s.ocarina(nota("G5"), 0.14, 0.7))
	poner(x, 0.16, s.ocarina(nota("C6"), 0.3, 0.7))
	poner(x, 0.1, chispas(0.3, 3, 3500, 6000, 71), 0.4)
	return x


def magia_apartar() -> np.ndarray:
	x = lienzo(1.8)
	poner(x, 0.0, soplido(0.9, 200.0, 2500.0, 81, 2.0), 0.9)
	poner(x, 0.15, chispas(0.8, 12, 2500, 7000, 82), 0.6)
	poner(x, 0.0, s.colchon(nota("D4"), 0.7, 0.7, 0.6), 0.6)
	poner(x, 0.5, s.tambor(80.0, 0.5), 0.5)
	return x


def recoger_objeto() -> np.ndarray:
	x = lienzo(1.0)
	poner(x, 0.0, barrido(400.0, 900.0, 0.08) * np.exp(-s.tiempo(s.segundos(0.08)) / 0.04), 0.5)
	for i, n in enumerate(["E6", "G#6", "B6"]):
		poner(x, 0.06 + i * 0.07, s.campana(nota(n), 0.4, 0.6))
	return x


def palabra_anotada() -> np.ndarray:
	"""Kalin anota la palabra: lápiz que raspa y una campanita."""
	x = lienzo(1.2)
	rng = np.random.default_rng(91)
	for i in range(5):
		trazo = s.filtro(s.ruido(s.segundos(0.07), 92 + i), "band", [2500.0, 7000.0]) * np.sin(np.linspace(0, np.pi, s.segundos(0.07)))
		poner(x, i * 0.08 + rng.uniform(0, 0.02), trazo, 0.5)
	poner(x, 0.45, s.campana(nota("B5"), 0.5, 0.6))
	poner(x, 0.55, s.campana(nota("E6"), 0.5, 0.6))
	return x


def camino_bloqueado() -> np.ndarray:
	x = lienzo(0.6)
	poner(x, 0.0, s.tunkul(80.0, 0.8))
	poner(x, 0.0, s.marimba(nota("D4"), 0.15, 0.5))
	poner(x, 0.12, s.marimba(nota("A3"), 0.25, 0.5))
	return s.filtro(x, "low", 2000.0)


def meta_alcanzada() -> np.ndarray:
	x = lienzo(1.6)
	for i, n in enumerate(["D5", "E5", "F#5", "A5", "D6"]):
		poner(x, i * 0.07, s.marimba(nota(n), 0.3, 0.75))
	poner(x, 0.35, s.campana(nota("A6"), 0.8, 0.6))
	poner(x, 0.35, s.campana(nota("D7"), 0.8, 0.4))
	poner(x, 0.3, chispas(0.6, 7, 3000, 7000, 101), 0.5)
	return x


def salto() -> np.ndarray:
	x = lienzo(0.4)
	n = s.segundos(0.22)
	poner(x, 0.0, barrido(220.0, 620.0, 0.22, 0.6) * np.sin(np.linspace(0, np.pi, n)) * 0.6)
	poner(x, 0.0, soplido(0.2, 800.0, 3000.0, 111), 0.3)
	return x


# ─── Historia y cinemáticas ─────────────────────────────────────────────────

def dialogo_avanzar() -> np.ndarray:
	x = lienzo(0.08)
	poner(x, 0.0, s.filtro(s.ruido(s.segundos(0.03), 121), "band", [1500.0, 5000.0]) * np.linspace(1, 0, s.segundos(0.03)), 0.5)
	poner(x, 0.0, tono(1750.0, 0.06, 0.025), 0.4)
	return x


def animal_tocar() -> np.ndarray:
	n = s.segundos(0.16)
	t = s.tiempo(n)
	x = barrido(950.0, 480.0, 0.16, 0.5)
	x += 0.3 * barrido(1900.0, 960.0, 0.16, 0.5)
	return s.ataque_suave(x * np.exp(-t / 0.06), 1.0)


def trueno(semilla: int) -> np.ndarray:
	"""Relámpago: chasquidos del rayo, rodar grave que viaja de un lado a otro y una
	capa media para que se oiga también en bocinas pequeñas (estéreo)."""
	dur = 4.5
	n = s.segundos(dur)
	t = s.tiempo(n)
	rng = np.random.default_rng(semilla)
	# El rayo: tres o cuatro chasquidos muy seguidos.
	chasquido = np.zeros(n)
	for k in range(int(rng.integers(3, 5))):
		inicio = rng.uniform(0.0, 0.28) if k else 0.0
		desde = s.segundos(inicio)
		largo = n - desde
		rafaga = s.filtro(s.ruido(largo, semilla * 31 + k), "band", [500.0, 4500.0], 2)
		chasquido[desde:] += rafaga * np.exp(-s.tiempo(largo) / rng.uniform(0.04, 0.09)) * rng.uniform(0.5, 1.0)
	# Rodar: golpes de energía que se apagan con el tiempo.
	rodar = np.zeros(n)
	for _ in range(7):
		centro = rng.uniform(0.15, 2.8)
		rodar += np.exp(-((t - centro) / rng.uniform(0.2, 0.7)) ** 2) * rng.uniform(0.5, 1.0)
	rodar = np.minimum(t / 0.06, 1.0) * np.clip(rodar, 0.0, 1.2) * np.exp(-t / 1.6)
	canales = []
	for c in range(2):
		pardo = np.cumsum(s.ruido(n, semilla * 20 + c))
		grave = s.filtro(pardo - np.mean(pardo), "band", [28.0, 180.0], 4)
		grave /= np.max(np.abs(grave)) or 1.0
		medio = s.filtro(s.ruido(n, semilla * 40 + c), "band", [120.0, 600.0], 2)
		medio /= np.max(np.abs(medio)) or 1.0
		# El retumbo se mueve un poco de un oído a otro.
		lado = 1.0 + 0.25 * np.sin(2 * np.pi * 0.35 * t + c * np.pi)
		canales.append(chasquido * 0.35 + (grave * 1.0 + medio * 0.45) * rodar * lado)
	x = np.stack(canales, axis=1)
	x /= np.max(np.abs(x)) or 1.0
	# Saturación ligera: engorda el retumbo sin volverlo onda cuadrada.
	return np.tanh(x * 1.2) / np.tanh(1.2)


def retumbo() -> np.ndarray:
	n = s.segundos(1.6)
	t = s.tiempo(n)
	pardo = np.cumsum(s.ruido(n, 131))
	pardo = s.filtro(pardo - np.mean(pardo), "band", [30.0, 200.0])
	pardo /= np.max(np.abs(pardo)) or 1.0
	golpe = np.zeros(n)
	grave = s.bombo(45.0, 0.7)
	golpe[: min(n, len(grave))] = grave[:n]
	return pardo * np.minimum(t / 0.05, 1) * np.exp(-t / 0.5) + golpe * 0.6


def destello() -> np.ndarray:
	x = lienzo(1.2)
	poner(x, 0.0, soplido(0.5, 2000.0, 9000.0, 141, 0.8), 0.6)
	poner(x, 0.02, s.campana(nota("E7"), 0.6, 0.6))
	poner(x, 0.02, s.campana(nota("B7"), 0.6, 0.4))
	return x


def cartel_caracol() -> np.ndarray:
	"""Caracol (concha marina soplada): anuncia un mundo nuevo."""
	dur = 2.4
	n = s.segundos(dur)
	t = s.tiempo(n)
	f = nota("F4") * (0.94 + 0.06 * np.minimum(t / 0.25, 1.0)) * (1.0 + 0.003 * np.sin(2 * np.pi * 4.5 * t))
	fase = 2 * np.pi * np.cumsum(f) / s.SR
	x = sum((1.0 / k) * np.sin(k * fase) for k in range(1, 14))
	formantes = sum(s.filtro(x, "band", [fc * 0.8, fc * 1.25]) * a for fc, a in ((520.0, 1.0), (1150.0, 0.55), (2500.0, 0.2)))
	soplo = s.filtro(s.ruido(n, 151), "band", [400.0, 2500.0]) * 0.12
	env = np.minimum(t / 0.35, 1.0) * np.clip((dur - t) / 0.6, 0, 1)
	return (formantes + soplo) * env


def portal_abrir() -> np.ndarray:
	x = lienzo(4.0)
	poner(x, 0.0, soplido(2.5, 120.0, 1800.0, 161, 1.0), 0.8)
	for i, n in enumerate(["D4", "A4", "D5", "F#5"]):
		poner(x, 0.3 + i * 0.25, s.coro(nota(n), 2.0, 0.9, "a"), 1.4)
	poner(x, 0.0, s.bombo(45.0, 0.8), 0.7)
	poner(x, 1.4, chispas(1.4, 18, 2500, 7500, 162), 0.6)
	poner(x, 1.3, s.campana(nota("D7"), 1.0, 0.6))
	return x


def portal_cruzar() -> np.ndarray:
	x = lienzo(2.6)
	poner(x, 0.0, soplido(1.6, 300.0, 6000.0, 171, 1.8), 0.9)
	n = s.segundos(1.6)
	poner(x, 0.0, barrido(220.0, 1760.0, 1.6, 1.4) * np.sin(np.linspace(0, np.pi, n)) ** 2 * 0.35)
	poner(x, 0.8, chispas(1.0, 14, 3000, 8000, 172), 0.6)
	return x


def chispas_magia() -> np.ndarray:
	return chispas(1.0, 14, 2500, 7000, 181)


def paginas_revolotear() -> np.ndarray:
	x = lienzo(1.8)
	rng = np.random.default_rng(191)
	for i in range(7):
		poner(x, rng.uniform(0, 1.3), papel(rng.uniform(0.15, 0.35), 192 + i), rng.uniform(0.4, 0.9))
	return x


def muebles_volando() -> np.ndarray:
	x = lienzo(2.4)
	poner(x, 0.0, soplido(2.2, 250.0, 900.0, 201, 0.8), 0.9)
	rng = np.random.default_rng(202)
	for i in range(6):
		poner(x, rng.uniform(0.3, 1.9), golpe_madera(rng.uniform(300.0, 650.0), rng.uniform(0.5, 1.0)), 0.7)
	return x


def hojas_viento() -> np.ndarray:
	x = lienzo(2.2)
	poner(x, 0.0, soplido(2.1, 500.0, 1400.0, 211, 0.7), 0.7)
	n = s.segundos(2.0)
	hojas = s.filtro(s.ruido(n, 212) * (np.random.default_rng(213).random(n) < 0.3), "band", [2500.0, 9000.0])
	poner(x, 0.1, hojas * np.sin(np.linspace(0, np.pi, n)), 0.5)
	return x


def despertar() -> np.ndarray:
	x = lienzo(1.6)
	for i, n in enumerate(["A5", "C#6", "E6"]):
		poner(x, i * 0.18, s.campana(nota(n), 0.7, 0.55))
	poner(x, 0.0, s.colchon(nota("A4"), 0.9, 0.6, 0.3), 0.7)
	return x


# ─── Mundos ──────────────────────────────────────────────────────────────────

def camino_trazo() -> np.ndarray:
	"""Golpecito de marimba; el juego sube el tono en cada casilla."""
	return s.marimba(nota("A5"), 0.12, 0.55)[: s.segundos(0.35)]


def camino_borrar() -> np.ndarray:
	return soplido(0.25, 2500.0, 600.0, 221)


def camino_conectado() -> np.ndarray:
	x = lienzo(1.1)
	for i, n in enumerate(["G5", "A5", "B5", "D6"]):
		poner(x, i * 0.06, s.marimba(nota(n), 0.25, 0.75))
	poner(x, 0.0, s.sonaja(0.6, 0.3, 4), 0.5)
	poner(x, 0.25, s.campana(nota("G6"), 0.5, 0.5))
	return x


def palabra_tomar() -> np.ndarray:
	x = lienzo(0.5)
	poner(x, 0.0, s.pulsada(nota("E5"), 0.12, 0.6, 0.8))
	poner(x, 0.0, barrido(500.0, 1100.0, 0.05) * np.linspace(1, 0, s.segundos(0.05)), 0.3)
	return x


def palabra_soltar() -> np.ndarray:
	x = lienzo(0.5)
	poner(x, 0.0, golpe_madera(800.0, 0.8))
	poner(x, 0.0, s.pulsada(nota("B4"), 0.15, 0.6, 0.6), 0.8)
	return x


def palabra_regresar() -> np.ndarray:
	return soplido(0.22, 1800.0, 700.0, 231) * 0.8


def hechizo_lanzar() -> np.ndarray:
	x = lienzo(1.8)
	poner(x, 0.0, soplido(0.7, 300.0, 4000.0, 241, 1.6), 0.8)
	for i, n in enumerate(["D5", "A5", "D6", "F#6"]):
		poner(x, 0.15 + i * 0.06, s.campana(nota(n), 0.6, 0.55))
	poner(x, 0.4, chispas(0.8, 12, 3000, 7500, 242), 0.55)
	return x


def comida_servir() -> np.ndarray:
	"""Plato de barro que se apoya y un brillo de «¡listo!»."""
	x = lienzo(1.0)
	barro = tono(1750.0, 0.5, 0.25, ((1, 1.0), (1.93, 0.5), (3.1, 0.25), (4.4, 0.12)))
	poner(x, 0.0, barro, 0.6)
	poner(x, 0.0, s.tambor(210.0, 0.4), 0.4)
	poner(x, 0.12, s.campana(nota("A6"), 0.4, 0.5))
	poner(x, 0.18, chispas(0.3, 4, 3500, 6500, 251), 0.4)
	return x


def portal_energia() -> np.ndarray:
	x = lienzo(1.8)
	poner(x, 0.0, s.coro(nota("A4"), 0.8, 0.8, "o"), 1.4)
	poner(x, 0.0, soplido(1.0, 300.0, 2500.0, 261, 1.2), 0.5)
	poner(x, 0.6, s.campana(nota("E6"), 0.6, 0.6))
	return x


# Nombre → (función, sonoridad momentánea objetivo en dB).
EFECTOS = {
	# Interfaz
	"boton_clic": (boton_clic, -20.0),
	"boton_pasar": (boton_pasar, -32.0),
	"panel_abrir": (panel_abrir, -16.0),
	"panel_cerrar": (panel_cerrar, -17.0),
	"pausa_abrir": (pausa_abrir, -15.0),
	"pausa_cerrar": (pausa_cerrar, -16.0),
	"mapa_seleccionar": (mapa_seleccionar, -14.0),
	# Aciertos y progreso
	"acierto": (acierto, -11.0),
	"error_suave": (error_suave, -14.0),
	"palabra_aprendida": (palabra_aprendida, -12.0),
	"nivel_completado": (nivel_completado, -8.0),
	"mision_pausa": (mision_pausa, -14.0),
	# Libro
	"libro_abrir": (libro_abrir, -15.0),
	"libro_cerrar": (libro_cerrar, -14.0),
	"pagina_pasar": (pagina_pasar, -20.0),
	"pagina_recuperada": (pagina_recuperada, -11.0),
	# Exploración
	"examinar_objeto": (examinar_objeto, -13.0),
	"magia_apartar": (magia_apartar, -12.0),
	"recoger_objeto": (recoger_objeto, -13.0),
	"palabra_anotada": (palabra_anotada, -13.0),
	"camino_bloqueado": (camino_bloqueado, -15.0),
	"meta_alcanzada": (meta_alcanzada, -10.0),
	"salto": (salto, -15.0),
	# Historia
	"dialogo_avanzar": (dialogo_avanzar, -28.0),
	"animal_tocar": (animal_tocar, -14.0),
	"trueno_1": (lambda: trueno(1), -12.0),
	"trueno_2": (lambda: trueno(3), -13.0),
	"retumbo": (retumbo, -10.0),
	"destello": (destello, -14.0),
	"cartel_caracol": (cartel_caracol, -10.0),
	"portal_abrir": (portal_abrir, -9.0),
	"portal_cruzar": (portal_cruzar, -11.0),
	"chispas_magia": (chispas_magia, -16.0),
	"paginas_revolotear": (paginas_revolotear, -17.0),
	"muebles_volando": (muebles_volando, -13.0),
	"hojas_viento": (hojas_viento, -17.0),
	"despertar": (despertar, -15.0),
	# Mundos
	"camino_trazo": (camino_trazo, -18.0),
	"camino_borrar": (camino_borrar, -20.0),
	"camino_conectado": (camino_conectado, -11.0),
	"palabra_tomar": (palabra_tomar, -17.0),
	"palabra_soltar": (palabra_soltar, -16.0),
	"palabra_regresar": (palabra_regresar, -20.0),
	"hechizo_lanzar": (hechizo_lanzar, -11.0),
	"comida_servir": (comida_servir, -13.0),
	"portal_energia": (portal_energia, -13.0),
}

for _superficie in ("arena", "tierra", "pasto", "piedra"):
	for _variante in range(1, 5):
		EFECTOS[f"pasos_{_superficie}_{_variante}"] = ((lambda sup=_superficie, var=_variante: paso(sup, var)), -22.0)
