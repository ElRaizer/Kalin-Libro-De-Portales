"""Ambientes en bucle: mar, lluvia, viento, aves, grillos, milpa y portal.

Las modulaciones lentas usan periodos que dividen el largo del bucle y la cola
se suma al inicio, así que se repiten sin cortes.
"""
from __future__ import annotations

import math

import numpy as np

import sintesis as s
from efectos import banda_variable, poner


def _lento(n: int, largo: int, ciclos: int, fase: float = 0.0) -> np.ndarray:
	"""Onda lenta que completa `ciclos` vueltas exactas dentro del bucle."""
	return 0.5 + 0.5 * np.sin(2 * np.pi * ciclos * np.arange(n) / largo + fase)


def _estereo(izq: np.ndarray, der: np.ndarray) -> np.ndarray:
	return np.stack([izq, der], axis=1)


def _cerrar(x: np.ndarray, largo: int, rms_db: float) -> np.ndarray:
	"""Funde el sobrante final con el inicio para que el bucle empalme sin saltos."""
	fundido = len(x) - largo
	salida = x[:largo].copy()
	rampa = np.linspace(0.0, 1.0, fundido)[:, None]
	salida[:fundido] = x[:fundido] * rampa + x[largo:] * (1.0 - rampa)
	return s.limitar(s.normalizar_rms(salida, rms_db), -3.0)


# ─── Aves e insectos ─────────────────────────────────────────────────────────

def pio(f0: float, f1: float, dur: float, vel: float = 1.0) -> np.ndarray:
	n = s.segundos(dur)
	p = np.linspace(0, 1, n)
	f = f0 + (f1 - f0) * np.sin(p * np.pi / 2)
	x = np.sin(2 * np.pi * np.cumsum(f) / s.SR)
	return x * np.sin(np.pi * p) ** 2 * vel


def canto(especie: int, rng: np.random.Generator) -> np.ndarray:
	"""Frases cortas de distintas aves (inventadas, no imitan una especie real)."""
	x = np.zeros(s.segundos(2.0))
	base = rng.uniform(0.9, 1.15)
	if especie == 0:  # silbido de dos notas que baja
		poner(x, 0.0, pio(3200 * base, 3600 * base, 0.12))
		poner(x, 0.18, pio(2600 * base, 2300 * base, 0.22))
	elif especie == 1:  # trino rápido
		n = s.segundos(0.6)
		t = s.tiempo(n)
		trino = np.sin(2 * np.pi * 4200 * base * t + 3 * np.sin(2 * np.pi * 28 * t)) * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * t))
		poner(x, 0.0, trino * np.sin(np.linspace(0, np.pi, n)) * 0.6)
	elif especie == 2:  # pío-pío-pío ascendente
		for i in range(4):
			poner(x, i * 0.14, pio((2400 + i * 180) * base, (3000 + i * 180) * base, 0.08, 0.8))
	else:  # llamada grave y redonda, como de paloma
		for i, dur in enumerate((0.25, 0.18, 0.35)):
			n = s.segundos(dur)
			t = s.tiempo(n)
			arrullo = np.sin(2 * np.pi * 520 * base * t) * np.sin(np.linspace(0, np.pi, n))
			poner(x, i * 0.32, arrullo * 0.7)
	return x


def aves(largo: int, total: int, densidad: float, especies: tuple[int, ...], semilla: int) -> np.ndarray:
	rng = np.random.default_rng(semilla)
	salida = np.zeros((total, 2))
	cantidad = int(largo / s.SR * densidad)
	for _ in range(cantidad):
		frase = canto(int(rng.choice(especies)), rng) * rng.uniform(0.25, 0.8)
		pan = rng.uniform(-0.9, 0.9)
		inicio = rng.integers(0, largo)
		estereo = s.panear(frase, pan)
		fin = min(inicio + len(estereo), total)
		salida[inicio:fin] += estereo[: fin - inicio]
	return salida


def grillos(largo: int, total: int, cantidad: int, semilla: int) -> np.ndarray:
	"""Frecuencias con vueltas enteras dentro del bucle: la señal se repite exacta."""
	rng = np.random.default_rng(semilla)
	t = np.arange(total) / s.SR
	seg = largo / s.SR
	salida = np.zeros((total, 2))
	for _ in range(cantidad):
		portadora = round(rng.uniform(4000.0, 5200.0) * seg) / seg
		pulsos = round(rng.uniform(25.0, 40.0) * seg) / seg
		chirrido = rng.uniform(0.5, 1.1)
		fase = rng.uniform(0, 1)
		# Ritmos ajustados al bucle para que el último chirrido empalme con el primero.
		chirrido = largo / s.SR / round(largo / s.SR / chirrido)
		ventana = (((t / chirrido) + fase) % 1.0) < rng.uniform(0.25, 0.45)
		x = np.sin(2 * np.pi * portadora * t) * (0.5 + 0.5 * np.sin(2 * np.pi * pulsos * t)) ** 2 * ventana
		x = s.filtro(x, "band", [3000.0, 7000.0]) * rng.uniform(0.3, 0.8)
		salida += s.panear(x, rng.uniform(-0.9, 0.9))
	return salida


# ─── Ambientes ───────────────────────────────────────────────────────────────

def olas_mar(seg: float = 32.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(3.0)
	canales = []
	for c in range(2):
		base = s.filtro(s.ruido(n, 300 + c), "low", 700.0)
		espuma = s.filtro(s.ruido(n, 310 + c), "band", [1500.0, 6000.0])
		ola = _lento(n, largo, 4, c * 0.6) ** 3
		ola2 = _lento(n, largo, 5, 1.7 + c) ** 4
		canales.append(base * (0.25 + 0.75 * ola) + espuma * (0.08 + 0.4 * ola2 * ola))
	x = _estereo(*canales)
	x += aves(largo, n, 0.12, (0,), 320) * 0.15
	return _cerrar(x, largo, -24.0)


def lluvia_tormenta(seg: float = 30.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(3.0)
	rng = np.random.default_rng(400)
	canales = []
	for c in range(2):
		siseo = s.filtro(s.ruido(n, 401 + c), "band", [1200.0, 9000.0]) * 0.6
		gotas = s.filtro(s.ruido(n, 410 + c) * (rng.random(n) < 0.002), "band", [2000.0, 6000.0]) * 3.0
		viento = banda_variable(s.ruido(n, 420 + c), 250.0, 600.0, 2.0) * (0.3 + 0.7 * _lento(n, largo, 3, c))
		canales.append(siseo * (0.8 + 0.2 * _lento(n, largo, 6, c)) + gotas + viento * 0.8)
	x = _estereo(*canales)
	t = np.arange(n) / s.SR
	pardo = np.cumsum(s.ruido(n, 430))
	pardo = s.filtro(pardo - np.mean(pardo), "band", [30.0, 160.0])
	pardo /= np.max(np.abs(pardo)) or 1.0
	lejano = np.exp(-((t - seg * 0.55) / 1.2) ** 2) * pardo * 0.5
	x += _estereo(lejano, lejano * 0.8)
	return _cerrar(x, largo, -23.0)


def viento_suave(seg: float = 30.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.0)
	canales = []
	for c in range(2):
		r = s.ruido(n, 500 + c)
		silbido = s.filtro(r, "band", [300.0, 1200.0]) * (0.3 + 0.7 * _lento(n, largo, 3, c * 1.1) ** 2)
		hojas = s.filtro(s.ruido(n, 510 + c), "band", [2500.0, 7000.0]) * 0.15 * _lento(n, largo, 5, c)
		canales.append(silbido + hojas)
	return _cerrar(_estereo(*canales), largo, -27.0)


def selva_pajaros(seg: float = 40.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.5)
	hojas = _estereo(*(s.filtro(s.ruido(n, 600 + c), "band", [800.0, 5000.0]) * 0.08 * (0.6 + 0.4 * _lento(n, largo, 4, c)) for c in range(2)))
	x = hojas + aves(largo, n, 0.9, (0, 1, 2, 3), 610)
	return _cerrar(x, largo, -27.0)


def grillos_atardecer(seg: float = 30.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.5)
	brisa = _estereo(*(s.filtro(s.ruido(n, 700 + c), "band", [200.0, 900.0]) * 0.12 * _lento(n, largo, 3, c) for c in range(2)))
	x = brisa + grillos(largo, n, 6, 710)
	x += aves(largo, n, 0.15, (3,), 720) * 0.6
	return _cerrar(x, largo, -27.0)


def milpa_manana(seg: float = 40.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.5)
	maizal = _estereo(*(s.filtro(s.ruido(n, 800 + c), "band", [1500.0, 7000.0]) * 0.12 * (0.3 + 0.7 * _lento(n, largo, 5, c * 2) ** 2) for c in range(2)))
	x = maizal + aves(largo, n, 0.6, (0, 2, 3), 810)
	return _cerrar(x, largo, -27.0)


def aldea_dia(seg: float = 40.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.5)
	brisa = _estereo(*(s.filtro(s.ruido(n, 900 + c), "band", [400.0, 3000.0]) * 0.07 * _lento(n, largo, 3, c) for c in range(2)))
	x = brisa + aves(largo, n, 0.35, (0, 2), 910)
	return _cerrar(x, largo, -29.0)


def portal_zumbido(seg: float = 24.0) -> np.ndarray:
	largo = s.segundos(seg)
	n = largo + s.segundos(2.0)
	t = np.arange(n) / s.SR
	ciclos = [round(f * seg) / seg for f in (55.0, 110.0, 165.0, 220.5, 330.0)]
	canales = []
	for c in range(2):
		zumbido = sum(np.sin(2 * np.pi * (f + c * 0.25 * (i + 1) / seg * 4) * t) / (i + 1) for i, f in enumerate(ciclos))
		zumbido *= 0.6 + 0.4 * _lento(n, largo, 6, c)
		brillo = s.filtro(s.ruido(n, 1000 + c), "band", [3000.0, 8000.0]) * 0.05 * _lento(n, largo, 4, c + 1)
		canales.append(zumbido * 0.4 + brillo)
	x = _estereo(*canales)
	rng = np.random.default_rng(1010)
	for _ in range(int(seg * 0.6)):
		f = s.midi_a_hz(rng.choice([86, 88, 90, 93, 95, 98]))
		campana = s.campana(round(f, 2), 0.4, 0.4) * rng.uniform(0.2, 0.5)
		inicio = rng.uniform(0, seg)
		estereo = s.panear(campana, rng.uniform(-0.8, 0.8))
		i = s.segundos(inicio)
		fin = min(i + len(estereo), n)
		x[i:fin] += estereo[: fin - i]
	return _cerrar(x, largo, -26.0)


AMBIENTES = {
	"ambiente_olas_mar": olas_mar,
	"ambiente_lluvia_tormenta": lluvia_tormenta,
	"ambiente_viento_suave": viento_suave,
	"ambiente_selva_pajaros": selva_pajaros,
	"ambiente_grillos_atardecer": grillos_atardecer,
	"ambiente_milpa_manana": milpa_manana,
	"ambiente_aldea_dia": aldea_dia,
	"ambiente_portal_zumbido": portal_zumbido,
}
