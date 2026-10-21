"""Bloques de síntesis para la música y los efectos de Kalin.

Todo el audio del juego se genera con estas funciones (no hay grabaciones ni
muestras de terceros), así que no tiene derechos de autor de nadie más.
Los instrumentos imitan la paleta sonora de la península: marimba, flauta de
carrizo, jarana (cuerdas rasgueadas), tunkul (tambor de tronco), sonajas,
caparazón de tortuga y caracol.
"""
from __future__ import annotations

import math
import subprocess
import wave
from functools import lru_cache
from pathlib import Path

import numpy as np
from scipy import signal

SR = 44100
RNG = np.random.default_rng(20261021)

# ─── Utilidades ──────────────────────────────────────────────────────────────

def segundos(n: float) -> int:
	return int(round(n * SR))


def tiempo(n: int) -> np.ndarray:
	return np.arange(n) / SR


def ruido(n: int, semilla: int | None = None) -> np.ndarray:
	rng = RNG if semilla is None else np.random.default_rng(semilla)
	return rng.uniform(-1.0, 1.0, n)


def db(valor: float) -> float:
	return 10.0 ** (valor / 20.0)


def filtro(x: np.ndarray, tipo: str, corte, orden: int = 2) -> np.ndarray:
	"""Filtro Butterworth: tipo 'low', 'high' o 'band'."""
	if isinstance(corte, (list, tuple)):
		corte = [min(max(c, 20.0), SR * 0.45) for c in corte]
	else:
		corte = min(max(corte, 20.0), SR * 0.45)
	sos = signal.butter(orden, corte, btype=tipo, fs=SR, output="sos")
	return signal.sosfilt(sos, x)


def envolvente(n: int, ataque: float, caida: float, sostener: float, soltar: float, duracion: float) -> np.ndarray:
	"""ADSR en segundos; `duracion` es el tiempo hasta que empieza a soltar."""
	t = tiempo(n)
	env = np.zeros(n)
	a = max(ataque, 1e-4)
	d = max(caida, 1e-4)
	env = np.where(t < a, t / a, env)
	en_caida = (t >= a) & (t < a + d)
	env = np.where(en_caida, 1.0 - (1.0 - sostener) * (t - a) / d, env)
	env = np.where((t >= a + d) & (t < duracion), sostener, env)
	nivel_final = np.interp(duracion, [0, a, a + d, max(duracion, a + d + 1e-4)], [0, 1, sostener, sostener])
	despues = t >= duracion
	env = np.where(despues, nivel_final * np.exp(-(t - duracion) / max(soltar, 1e-4) * 4.0), env)
	return env


def decaimiento(n: int, t60: float) -> np.ndarray:
	"""Caída exponencial que pierde 60 dB en `t60` segundos."""
	return np.exp(-6.9078 * tiempo(n) / max(t60, 1e-4))


def ataque_suave(x: np.ndarray, ms: float = 2.0) -> np.ndarray:
	n = min(len(x), segundos(ms / 1000.0))
	if n > 1:
		rampa = np.linspace(0.0, 1.0, n)
		x[:n] *= rampa if x.ndim == 1 else rampa[:, None]
	return x


def final_suave(x: np.ndarray, ms: float = 8.0) -> np.ndarray:
	n = min(len(x), segundos(ms / 1000.0))
	if n > 1:
		rampa = np.linspace(1.0, 0.0, n)
		x[-n:] *= rampa if x.ndim == 1 else rampa[:, None]
	return x


NOTAS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}


def frecuencia(nota: str | float) -> float:
	"""'A4', 'F#3', 'Bb5' → Hz. Un número se devuelve tal cual."""
	if not isinstance(nota, str):
		return float(nota)
	nombre = nota[0].upper()
	resto = nota[1:]
	alteracion = 0
	while resto and resto[0] in "#b":
		alteracion += 1 if resto[0] == "#" else -1
		resto = resto[1:]
	octava = int(resto)
	midi = 12 * (octava + 1) + NOTAS[nombre] + alteracion
	return 440.0 * 2.0 ** ((midi - 69) / 12.0)


def midi_a_hz(midi: float) -> float:
	return 440.0 * 2.0 ** ((midi - 69) / 12.0)


# ─── Instrumentos melódicos ─────────────────────────────────────────────────

@lru_cache(maxsize=4096)
def marimba(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
	"""Barra de madera con resonador: parciales 1 : 3.93 : 9.2 y golpe de baqueta."""
	t60 = float(np.clip(2.2 * (220.0 / f) ** 0.55, 0.35, 2.6))
	n = segundos(min(dur + t60, t60 * 1.1) + 0.05)
	t = tiempo(n)
	x = np.sin(2 * np.pi * f * t) * decaimiento(n, t60)
	x += 0.30 * vel * np.sin(2 * np.pi * f * 3.93 * t) * decaimiento(n, t60 * 0.22)
	if f * 9.2 < SR * 0.45:
		x += 0.10 * vel * np.sin(2 * np.pi * f * 9.2 * t) * decaimiento(n, t60 * 0.08)
	golpe = filtro(ruido(segundos(0.012), int(f)), "band", [f * 2.0, min(f * 12.0, 9000.0)]) * np.linspace(1, 0, segundos(0.012)) * 0.35 * vel
	x[: len(golpe)] += golpe
	return ataque_suave(x * vel, 1.5)


@lru_cache(maxsize=4096)
def flauta(f: float, dur: float, vel: float = 0.8, vibrato: float = 1.0) -> np.ndarray:
	"""Flauta de carrizo: armónicos suaves, soplo y vibrato que llega tarde."""
	n = segundos(dur + 0.18)
	t = tiempo(n)
	vib = 1.0 + 0.0045 * vibrato * np.sin(2 * np.pi * 5.2 * t) * np.clip((t - 0.22) / 0.3, 0, 1)
	entrada = 1.0 - 0.012 * np.exp(-t / 0.03)
	fase = 2 * np.pi * np.cumsum(f * vib * entrada) / SR
	x = np.sin(fase) + 0.42 * np.sin(2 * fase) + 0.16 * np.sin(3 * fase) + 0.06 * np.sin(4 * fase)
	soplo = filtro(ruido(n, int(f * 7)), "band", [f * 1.2, min(f * 4.0, 12000.0)]) * 0.10
	chif = filtro(ruido(n, int(f * 3)), "high", 2000.0) * np.exp(-t / 0.025) * 0.25
	env = envolvente(n, 0.06, 0.12, 0.85, 0.12, dur)
	return (x * 0.55 + soplo + chif) * env * vel


@lru_cache(maxsize=4096)
def ocarina(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
	"""Silbato de barro: casi senoidal, redondo."""
	n = segundos(dur + 0.15)
	t = tiempo(n)
	vib = 1.0 + 0.004 * np.sin(2 * np.pi * 4.6 * t) * np.clip((t - 0.3) / 0.4, 0, 1)
	fase = 2 * np.pi * np.cumsum(f * vib) / SR
	x = np.sin(fase) + 0.08 * np.sin(2 * fase) + 0.05 * np.sin(3 * fase)
	soplo = filtro(ruido(n, int(f * 11)), "band", [f * 0.9, f * 2.5]) * 0.05
	env = envolvente(n, 0.05, 0.1, 0.9, 0.1, dur)
	return (x * 0.7 + soplo) * env * vel


@lru_cache(maxsize=4096)
def clarinete(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
	"""Clarinete de banda jaranera: armónicos impares y algo de caña."""
	n = segundos(dur + 0.12)
	t = tiempo(n)
	vib = 1.0 + 0.003 * np.sin(2 * np.pi * 5.6 * t) * np.clip((t - 0.25) / 0.3, 0, 1)
	fase = 2 * np.pi * np.cumsum(f * vib) / SR
	x = np.zeros(n)
	for k, a in ((1, 1.0), (3, 0.55), (5, 0.30), (7, 0.16), (9, 0.08), (2, 0.08), (4, 0.05)):
		if f * k < SR * 0.45:
			x += a * np.sin(k * fase)
	x = filtro(x, "low", min(f * 6.0, 7000.0))
	env = envolvente(n, 0.035, 0.1, 0.82, 0.08, dur)
	return x * 0.45 * env * vel


@lru_cache(maxsize=4096)
def pulsada(f: float, dur: float, vel: float = 0.8, brillo: float = 0.5) -> np.ndarray:
	"""Cuerda pulsada (jarana, requinto) con Karplus-Strong."""
	sustain = float(np.clip(dur + 0.6, 0.4, 2.2))
	n = segundos(sustain)
	# Lazo: retardo N + promedio de dos muestras (½ muestra) + paso-todo fraccional.
	periodo = SR / f
	retardo = int(math.floor(periodo - 0.5))
	fraccion = max(periodo - 0.5 - retardo, 0.05)
	c = (1.0 - fraccion) / (1.0 + fraccion)
	excitacion = np.zeros(n)
	pulso = ruido(retardo + 1, int(f * 13))
	pulso = filtro(pulso, "low", 1500.0 + 6000.0 * brillo, 1)
	excitacion[: len(pulso)] = pulso
	perdida = 0.996 if f < 300 else 0.993
	a = np.zeros(retardo + 3)
	a[0] = 1.0
	a[1] = c
	a[retardo] += -perdida * 0.5 * c
	a[retardo + 1] += -perdida * 0.5 * (1.0 + c)
	a[retardo + 2] += -perdida * 0.5
	x = signal.lfilter([1.0, c], a, excitacion)
	x = filtro(x, "high", 70.0, 1)
	pico = np.max(np.abs(x)) or 1.0
	x = x / pico
	x *= envolvente(n, 0.002, 0.05, 1.0, 0.08, max(dur, 0.05) + 0.25)
	return final_suave(x * vel * 0.7)


@lru_cache(maxsize=4096)
def bajo(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
	"""Bajo redondo (marimba grave / bajo de banda)."""
	n = segundos(dur + 0.25)
	t = tiempo(n)
	x = np.sin(2 * np.pi * f * t) + 0.35 * np.sin(4 * np.pi * f * t) + 0.12 * np.sin(6 * np.pi * f * t)
	env = envolvente(n, 0.008, 0.25, 0.55, 0.12, dur) * decaimiento(n, 2.5)
	return ataque_suave(x * env * vel * 0.8)


@lru_cache(maxsize=4096)
def campana(f: float, dur: float, vel: float = 0.8) -> np.ndarray:
	"""Celesta / campanita de magia (FM)."""
	t60 = float(np.clip(2.6 * (523.0 / f) ** 0.4, 0.8, 3.5))
	n = segundos(t60)
	t = tiempo(n)
	indice = 2.2 * np.exp(-t / 0.18)
	x = np.sin(2 * np.pi * f * t + indice * np.sin(2 * np.pi * f * 3.5 * t))
	x += 0.25 * np.sin(2 * np.pi * f * 2.0 * t) * decaimiento(n, t60 * 0.5)
	return ataque_suave(x * decaimiento(n, t60) * vel * 0.55, 1.0)


@lru_cache(maxsize=1024)
def colchon(f: float, dur: float, vel: float = 0.8, brillo: float = 0.5) -> np.ndarray:
	"""Colchón suave de cuerdas mágicas: sierras desafinadas, filtradas."""
	n = segundos(dur + 1.2)
	t = tiempo(n)
	x = np.zeros(n)
	for desvio, fase0 in ((-0.10, 0.0), (0.0, 1.3), (0.11, 2.1)):
		fd = f * 2.0 ** (desvio / 12.0)
		fase = (fd * t + fase0 / (2 * np.pi)) % 1.0
		x += 2.0 * fase - 1.0
	x = filtro(x, "low", f * (2.0 + 6.0 * brillo), 2)
	x += 0.6 * np.sin(2 * np.pi * f * t)
	env = envolvente(n, min(0.9, dur * 0.4), 0.3, 0.85, 0.9, dur)
	return x * env * vel * 0.18


@lru_cache(maxsize=1024)
def coro(f: float, dur: float, vel: float = 0.8, vocal: str = "a") -> np.ndarray:
	"""Coro etéreo «aah/ooh» con formantes aproximados."""
	formantes = {"a": ((730, 1.0), (1090, 0.5), (2440, 0.18)), "o": ((450, 1.0), (800, 0.45), (2830, 0.08)), "u": ((325, 1.0), (700, 0.3), (2530, 0.05))}[vocal]
	n = segundos(dur + 1.0)
	t = tiempo(n)
	x = np.zeros(n)
	for desvio in (-0.07, 0.0, 0.08):
		fd = f * 2.0 ** (desvio / 12.0)
		vib = 1.0 + 0.004 * np.sin(2 * np.pi * (4.8 + desvio) * t + desvio * 20)
		fase = 2 * np.pi * np.cumsum(fd * vib) / SR
		for k in range(1, 30):
			fk = fd * k
			if fk > 5000:
				break
			peso = sum(a * math.exp(-((fk - fc) / (fc * 0.18)) ** 2) for fc, a in formantes) + 0.02
			x += peso / k ** 0.6 * np.sin(k * fase)
	env = envolvente(n, min(0.7, dur * 0.35), 0.3, 0.9, 0.7, dur)
	return x * env * vel * 0.06


# ─── Percusión ───────────────────────────────────────────────────────────────

@lru_cache(maxsize=256)
def tunkul(f: float = 120.0, vel: float = 0.8) -> np.ndarray:
	"""Tunkul: tambor de tronco con lengüetas; madera grave y redonda."""
	n = segundos(0.55)
	t = tiempo(n)
	caida_tono = f * (1.0 + 0.18 * np.exp(-t / 0.02))
	fase = 2 * np.pi * np.cumsum(caida_tono) / SR
	x = np.sin(fase) * decaimiento(n, 0.42) + 0.35 * np.sin(fase * 2.71) * decaimiento(n, 0.12)
	golpe = filtro(ruido(segundos(0.01), int(f)), "band", [600.0, 3000.0]) * np.linspace(1, 0, segundos(0.01))
	x[: len(golpe)] += golpe * 0.4
	return ataque_suave(x * vel * 0.9, 0.8)


@lru_cache(maxsize=256)
def tambor(f: float = 95.0, vel: float = 0.8) -> np.ndarray:
	"""Tambor de mano (huéhuetl): cuero grave con palmada."""
	n = segundos(0.7)
	t = tiempo(n)
	tono = f * (1.0 + 0.6 * np.exp(-t / 0.035))
	fase = 2 * np.pi * np.cumsum(tono) / SR
	x = np.sin(fase) * decaimiento(n, 0.55)
	palmada = filtro(ruido(n, int(f * 5)), "band", [400.0, 2500.0]) * decaimiento(n, 0.06) * 0.35
	return ataque_suave((x + palmada) * vel, 0.8)


@lru_cache(maxsize=256)
def sonaja(vel: float = 0.6, largo: float = 0.09, semilla: int = 1) -> np.ndarray:
	"""Sonaja de semillas: muchos granos pequeños de ruido agudo."""
	n = segundos(largo + 0.05)
	rng = np.random.default_rng(semilla)
	x = np.zeros(n)
	for _ in range(int(40 * largo / 0.09)):
		pos = int(rng.beta(1.4, 3.0) * segundos(largo))
		grano = segundos(0.0015)
		if pos + grano < n:
			x[pos:pos + grano] += rng.uniform(-1, 1, grano) * rng.uniform(0.3, 1.0)
	x = filtro(x, "band", [3500.0, 11000.0])
	return final_suave(x * vel * 0.9)


@lru_cache(maxsize=256)
def caparazon(f: float = 900.0, vel: float = 0.7) -> np.ndarray:
	"""Caparazón de tortuga (áak) golpeado: clic de madera agudo."""
	n = segundos(0.18)
	t = tiempo(n)
	x = np.sin(2 * np.pi * f * t) * decaimiento(n, 0.07) + 0.6 * np.sin(2 * np.pi * f * 2.13 * t) * decaimiento(n, 0.04)
	x += filtro(ruido(n, int(f)), "band", [1500.0, 6000.0]) * decaimiento(n, 0.01) * 0.6
	return ataque_suave(x * vel * 0.7, 0.5)


@lru_cache(maxsize=64)
def bombo(f: float = 52.0, vel: float = 0.8) -> np.ndarray:
	"""Golpe grave y largo para tormentas y momentos épicos."""
	n = segundos(1.4)
	t = tiempo(n)
	tono = f * (1.0 + 1.2 * np.exp(-t / 0.05))
	fase = 2 * np.pi * np.cumsum(tono) / SR
	x = np.sin(fase) * decaimiento(n, 1.2)
	x += filtro(ruido(n, 9), "low", 300.0) * decaimiento(n, 0.25) * 0.5
	return ataque_suave(x * vel, 1.0)


# ─── Mezcla ──────────────────────────────────────────────────────────────────

def panear(x: np.ndarray, pan: float) -> np.ndarray:
	"""Mono → estéreo con paneo de potencia constante (-1 izquierda, 1 derecha)."""
	angulo = (pan + 1.0) * math.pi / 4.0
	return np.stack([x * math.cos(angulo), x * math.sin(angulo)], axis=1)


def respuesta_reverb(t60: float = 2.0, predelay: float = 0.018, brillo: float = 0.5, semilla: int = 3) -> np.ndarray:
	"""Respuesta de impulso sintética en estéreo (sala de madera / cueva)."""
	n = segundos(t60)
	t = tiempo(n)
	pre = segundos(predelay)
	canales = []
	for c in range(2):
		r = ruido(n, semilla + c) * decaimiento(n, t60)
		oscuro = filtro(r, "low", 1200.0 + 5000.0 * brillo)
		mezcla = np.clip(t / (t60 * 0.6), 0, 1)
		r = r * (1 - mezcla) * 0.6 + oscuro * (0.4 + 0.6 * mezcla)
		r = np.concatenate([np.zeros(pre), r])
		canales.append(r)
	ir = np.stack(canales, axis=1)
	return ir / np.sqrt(np.sum(ir ** 2) / 2.0)


def reverberar(x: np.ndarray, ir: np.ndarray) -> np.ndarray:
	salida = np.zeros((len(x) + len(ir) - 1, 2))
	for c in range(2):
		salida[:, c] = signal.fftconvolve(x[:, c], ir[:, c])
	return salida


def limitar(x: np.ndarray, techo_db: float = -1.0) -> np.ndarray:
	"""Saturación suave y techo de pico."""
	techo = db(techo_db)
	x = np.tanh(x / techo * 0.9) / 0.9 * techo
	pico = np.max(np.abs(x)) or 1.0
	if pico > techo:
		x *= techo / pico
	return x


def normalizar_rms(x: np.ndarray, objetivo_db: float) -> np.ndarray:
	rms = math.sqrt(float(np.mean(x ** 2))) or 1e-9
	return x * db(objetivo_db) / rms


def normalizar_pico(x: np.ndarray, objetivo_db: float) -> np.ndarray:
	pico = float(np.max(np.abs(x))) or 1e-9
	return x * db(objetivo_db) / pico


def sonoridad_momentanea(x: np.ndarray) -> float:
	"""Máximo RMS en ventanas de 50 ms: se parece más a lo que se oye que el pico."""
	mono = a_estereo(x).mean(axis=1)
	ventana = segundos(0.05)
	if len(mono) <= ventana:
		return math.sqrt(float(np.mean(mono ** 2))) or 1e-9
	energia = np.convolve(mono ** 2, np.ones(ventana) / ventana, mode="valid")
	return math.sqrt(float(np.max(energia))) or 1e-9


def normalizar_sonoridad(x: np.ndarray, objetivo_db: float, techo_db: float = -1.0) -> np.ndarray:
	"""Iguala la sonoridad momentánea y respeta un techo de pico."""
	x = x * db(objetivo_db) / sonoridad_momentanea(x)
	return limitar(x, techo_db)


def a_estereo(x: np.ndarray) -> np.ndarray:
	return x if x.ndim == 2 else np.stack([x, x], axis=1)


def envolver_bucle(x: np.ndarray, largo: int) -> np.ndarray:
	"""Suma la cola que sobra al inicio para que el bucle no tenga cortes."""
	x = a_estereo(x)
	salida = x[:largo].copy()
	cola = x[largo:]
	while len(cola):
		trozo = cola[:largo]
		salida[: len(trozo)] += trozo
		cola = cola[largo:]
	return salida


# ─── Exportación ─────────────────────────────────────────────────────────────

def guardar_ogg(x: np.ndarray, ruta: Path, calidad: float = 4.0) -> None:
	"""Escribe un WAV temporal y lo convierte a Ogg Vorbis con ffmpeg."""
	ruta.parent.mkdir(parents=True, exist_ok=True)
	x = a_estereo(np.asarray(x, dtype=np.float64))
	datos = (np.clip(x, -1.0, 1.0) * 32767.0).astype("<i2")
	temporal = ruta.with_suffix(".tmp.wav")
	with wave.open(str(temporal), "wb") as w:
		w.setnchannels(2)
		w.setsampwidth(2)
		w.setframerate(SR)
		w.writeframes(datos.tobytes())
	subprocess.run(
		["ffmpeg", "-y", "-loglevel", "error", "-i", str(temporal), "-c:a", "libvorbis", "-q:a", str(calidad), "-map_metadata", "-1", str(ruta)],
		check=True,
	)
	temporal.unlink()
