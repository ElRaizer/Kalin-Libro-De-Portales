"""Música en bucle de Kalin. Cada función compone una pieza y la devuelve en estéreo.

Las melodías se escriben con grados de la escala para poder transportarlas:
	"1:1.5 2:.5 3:1 5:1"  → grado:duración (en tiempos)
	"6,"  una octava abajo · "1'" una octava arriba · "#4" alterado · "r" silencio
Los acordes se indican con el grado sobre el que se construye la tríada
("1", "4", "5"...); "5M" fuerza un acorde mayor, "5s" añade la séptima y "a/b" divide el compás.
"""
from __future__ import annotations

import math
import re

import numpy as np

import sintesis as s

MODOS = {
	"mayor": [0, 2, 4, 5, 7, 9, 11],
	"menor": [0, 2, 3, 5, 7, 8, 10],
	"dorico": [0, 2, 3, 5, 7, 9, 10],
	"lidio": [0, 2, 4, 6, 7, 9, 11],
	"mixolidio": [0, 2, 4, 5, 7, 9, 10],
}

# ─── Motor ───────────────────────────────────────────────────────────────────

class Pista:
	def __init__(self, n: int, pan: float, reverb: float, nivel_db: float, medida: str):
		self.buffer = np.zeros(n)
		self.pan = pan
		self.reverb = reverb
		self.nivel_db = nivel_db
		self.medida = medida


class Cancion:
	def __init__(self, bpm: float, compas: int, compases: int, tonica: int, modo: str = "mayor", reverb_t60: float = 2.0, reverb_brillo: float = 0.5, semilla: int = 1):
		self.bpm = bpm
		self.tiempo_s = 60.0 / bpm
		self.compas = compas
		self.compases = compases
		self.tonica = tonica
		self.escala = MODOS[modo]
		self.largo = s.segundos(compases * compas * self.tiempo_s)
		self.cola = s.segundos(4.0)
		self.pistas: dict[str, Pista] = {}
		self.reverb_t60 = reverb_t60
		self.reverb_brillo = reverb_brillo
		self.rng = np.random.default_rng(semilla)

	# ── Pistas y notas ──
	def pista(self, nombre: str, pan: float = 0.0, reverb: float = 0.25, nivel_db: float = -20.0, medida: str = "rms") -> str:
		self.pistas[nombre] = Pista(self.largo + self.cola, pan, reverb, nivel_db, medida)
		return nombre

	def poner(self, nombre: str, tiempo_beats: float, x: np.ndarray, humano: float = 0.006) -> None:
		pista = self.pistas[nombre]
		inicio = s.segundos(tiempo_beats * self.tiempo_s + (self.rng.uniform(-humano, humano) if humano else 0.0))
		inicio = max(inicio, 0)
		fin = min(inicio + len(x), len(pista.buffer))
		if fin > inicio:
			pista.buffer[inicio:fin] += x[: fin - inicio]
		# Lo que pasa del final del bucle vuelve al inicio.
		if inicio + len(x) > len(pista.buffer):
			resto = x[fin - inicio:]
			pista.buffer[: len(resto)] += resto[: len(pista.buffer)]

	def beats(self, duracion: float) -> float:
		return duracion * self.tiempo_s

	# ── Teoría ──
	def grado_a_midi(self, grado: int, octava: int = 0, alteracion: int = 0) -> int:
		indice = grado - 1
		octava += indice // 7
		indice %= 7
		return self.tonica + self.escala[indice] + 12 * octava + alteracion

	def acorde(self, simbolo: str, octava: int = 0) -> list[int]:
		"""Tríada (y séptima opcional) diatónica sobre un grado."""
		grado, mayor, septima = self.leer_acorde(simbolo)
		notas = [self.grado_a_midi(grado, octava), self.grado_a_midi(grado + 2, octava), self.grado_a_midi(grado + 4, octava)]
		if mayor:
			notas[1] = notas[0] + 4
			notas[2] = notas[0] + 7
		if septima:
			notas.append(self.grado_a_midi(grado + 6, octava))
		return notas

	@staticmethod
	def leer_acorde(simbolo: str) -> tuple[int, bool, bool]:
		"""'5' tríada · '5M' tríada mayor forzada · '5s' con séptima."""
		coincide = re.fullmatch(r"([1-7])(M?)(s?)", simbolo)
		if coincide is None:
			raise ValueError(f"Acorde no válido: {simbolo}")
		return int(coincide.group(1)), coincide.group(2) == "M", coincide.group(3) == "s"

	def progresion(self, texto: str) -> list[list[tuple[float, float, str]]]:
		"""'1 4 5/1' → por compás, lista de (inicio, duración, acorde)."""
		resultado = []
		for compas in texto.split():
			partes = compas.split("/")
			dur = self.compas / len(partes)
			resultado.append([(i * dur, dur, p) for i, p in enumerate(partes)])
		return resultado

	@staticmethod
	def parsear_melodia(texto: str) -> list[tuple[int | None, int, int, float]]:
		"""Devuelve (grado, octava, alteración, duración); grado None es silencio."""
		notas = []
		for token in texto.replace("|", " ").split():
			nota, dur = token.split(":")
			dur = float(dur)
			if nota == "r":
				notas.append((None, 0, 0, dur))
				continue
			alteracion = 0
			while nota[0] in "#b":
				alteracion += 1 if nota[0] == "#" else -1
				nota = nota[1:]
			octava = nota.count("'") - nota.count(",")
			grado = int(nota.strip("',"))
			notas.append((grado, octava, alteracion, dur))
		return notas

	# ── Escritura musical ──
	def melodia(self, nombre: str, instrumento, texto: str, compas_inicio: int, octava: int = 1, vel: float = 0.8, tremolo: bool = False, armonia: int = 0, legato: float = 0.95, transponer: int = 0) -> None:
		t = compas_inicio * self.compas
		for grado, oct_rel, alteracion, dur in self.parsear_melodia(texto):
			if grado is not None:
				midi = self.grado_a_midi(grado + armonia, octava + oct_rel, alteracion) + transponer
				f = s.midi_a_hz(midi)
				acento = vel * (1.0 if (t % self.compas) == 0 else 0.9) * self.rng.uniform(0.92, 1.0)
				if tremolo and instrumento is s.marimba and dur >= 1.5:
					self._redoble(nombre, f, t, dur, acento)
				else:
					self.poner(nombre, t, instrumento(round(f, 3), round(self.beats(dur) * legato, 3), round(acento, 2)))
			t += dur

	def _redoble(self, nombre: str, f: float, inicio: float, dur: float, vel: float) -> None:
		"""Redoble de marimba: golpes rápidos alternados para sostener la nota."""
		golpes = int(self.beats(dur) * 13)
		for i in range(golpes):
			progreso = i / max(golpes - 1, 1)
			v = vel * (0.55 + 0.15 * math.sin(progreso * math.pi)) * (1.0 if i % 2 == 0 else 0.86)
			self.poner(nombre, inicio + i / 13.0 / self.tiempo_s, s.marimba(round(f, 3), 0.1, round(v, 2)), humano=0.003)

	def arpegio(self, nombre: str, instrumento, progresion: str, patron: list[tuple[float, int, float]], compas_inicio: int = 0, octava: int = 0, vel: float = 0.6, repetir: int = 1) -> None:
		"""patron: (tiempo dentro del acorde, índice de nota, duración); índice 3+ sube octava."""
		compases = self.progresion(progresion) * repetir
		for c, acordes in enumerate(compases):
			for inicio_acorde, dur_acorde, simbolo in acordes:
				notas = self.acorde(simbolo, octava)
				for t_rel, indice, dur in patron:
					if t_rel >= dur_acorde:
						continue
					midi = notas[indice % len(notas)] + 12 * (indice // len(notas))
					t = (compas_inicio + c) * self.compas + inicio_acorde + t_rel
					v = vel * self.rng.uniform(0.85, 1.0) * (1.0 if t_rel == 0 else 0.85)
					self.poner(nombre, t, instrumento(round(s.midi_a_hz(midi), 3), round(self.beats(dur), 3), round(v, 2)))

	def rasgueo(self, nombre: str, progresion: str, patron: list[tuple[float, str]], compas_inicio: int = 0, octava: int = 0, vel: float = 0.6, repetir: int = 1, brillo: float = 0.55) -> None:
		"""Jarana: 'D' rasgueo hacia abajo, 'U' hacia arriba (más suave), 'x' apagado."""
		compases = self.progresion(progresion) * repetir
		for c, acordes in enumerate(compases):
			for inicio_acorde, dur_acorde, simbolo in acordes:
				notas = self.acorde(simbolo, octava)
				voces = [notas[0], notas[1], notas[2], notas[0] + 12, notas[1] + 12]
				for t_rel, golpe in patron:
					if t_rel >= dur_acorde:
						continue
					orden = voces if golpe != "U" else list(reversed(voces[1:]))
					fuerza = {"D": 1.0, "U": 0.7, "x": 0.45}[golpe]
					dur = 0.12 if golpe == "x" else 0.5
					for i, midi in enumerate(orden):
						t = (compas_inicio + c) * self.compas + inicio_acorde + t_rel + i * 0.011 / self.tiempo_s
						self.poner(nombre, t, s.pulsada(round(s.midi_a_hz(midi), 3), dur, round(vel * fuerza * self.rng.uniform(0.85, 1.0), 2), brillo), humano=0.002)

	def bajo(self, nombre: str, progresion: str, patron: list[tuple[float, int, float]], compas_inicio: int = 0, octava: int = -1, vel: float = 0.8, instrumento=None, repetir: int = 1) -> None:
		"""patron: (tiempo, intervalo en grados desde la fundamental: 0, 4=quinta, 7=octava, duración)."""
		instrumento = instrumento or s.bajo
		compases = self.progresion(progresion) * repetir
		for c, acordes in enumerate(compases):
			for inicio_acorde, dur_acorde, simbolo in acordes:
				fundamental = self.acorde(simbolo, octava)[0]
				grado = self.leer_acorde(simbolo)[0]
				for t_rel, intervalo, dur in patron:
					if t_rel >= dur_acorde:
						continue
					if intervalo == 7:
						midi = fundamental + 12
					elif intervalo == 0:
						midi = fundamental
					else:
						midi = self.grado_a_midi(grado + intervalo, octava)
						if midi < fundamental:
							midi += 12
					t = (compas_inicio + c) * self.compas + inicio_acorde + t_rel
					self.poner(nombre, t, instrumento(round(s.midi_a_hz(midi), 3), round(self.beats(dur), 3), round(vel * self.rng.uniform(0.9, 1.0), 2)))

	def colchon(self, nombre: str, progresion: str, compas_inicio: int = 0, octava: int = 0, vel: float = 0.6, instrumento=None, repetir: int = 1, **extra) -> None:
		instrumento = instrumento or s.colchon
		compases = self.progresion(progresion) * repetir
		for c, acordes in enumerate(compases):
			for inicio_acorde, dur_acorde, simbolo in acordes:
				for midi in self.acorde(simbolo, octava):
					t = (compas_inicio + c) * self.compas + inicio_acorde
					self.poner(nombre, t, instrumento(round(s.midi_a_hz(midi), 3), round(self.beats(dur_acorde), 3), vel, **extra), humano=0.0)

	def ritmo(self, nombre: str, sonido, patron: str, compas_inicio: int = 0, compases: int | None = None, vel: float = 0.8) -> None:
		"""patron por compás: 'x' fuerte, 'o' suave, '.' nada. Varios compases con '|'."""
		bloques = patron.split("|")
		compases = compases if compases is not None else self.compases - compas_inicio
		for c in range(compases):
			bloque = bloques[c % len(bloques)].strip()
			paso = self.compas / len(bloque)
			for i, simbolo in enumerate(bloque):
				if simbolo == ".":
					continue
				fuerza = 1.0 if simbolo == "x" else 0.55
				t = (compas_inicio + c) * self.compas + i * paso
				self.poner(nombre, t, sonido(fuerza * vel * self.rng.uniform(0.85, 1.0)), humano=0.004)

	# ── Mezcla final ──
	def mezclar(self, rms_db: float = -19.0) -> np.ndarray:
		total = self.largo + self.cola
		seco = np.zeros((total, 2))
		envio = np.zeros((total, 2))
		for pista in self.pistas.values():
			x = pista.buffer
			if not np.any(x):
				continue
			if pista.medida == "rms":
				activo = x[np.abs(x) > 1e-4]
				rms = math.sqrt(float(np.mean(activo ** 2))) if len(activo) else 1.0
				x = x * s.db(pista.nivel_db) / max(rms, 1e-9)
			else:
				x = x * s.db(pista.nivel_db) / max(float(np.max(np.abs(x))), 1e-9)
			estereo = s.panear(x, pista.pan)
			seco += estereo
			envio += estereo * pista.reverb
		ir = s.respuesta_reverb(self.reverb_t60, brillo=self.reverb_brillo)
		mojado = s.reverberar(envio, ir)
		mezcla = np.zeros((total + len(ir), 2))
		mezcla[:total] += seco
		mezcla[: len(mojado)] += mojado * 0.55
		mezcla = s.filtro(mezcla.T, "high", 35.0).T
		bucle = s.envolver_bucle(mezcla, self.largo)
		bucle = s.normalizar_rms(bucle, rms_db)
		return s.limitar(bucle, -1.0)


def sacudida(v: float) -> np.ndarray:
	return s.sonaja(round(v, 2), 0.08, int(v * 1000) % 7 + 1)


def guiro(v: float) -> np.ndarray:
	"""Güiro rascado (banda jaranera)."""
	n = s.segundos(0.16)
	t = s.tiempo(n)
	raspado = (np.sin(2 * np.pi * 55 * t) > 0.6).astype(float)
	x = s.filtro(s.ruido(n, 4) * raspado, "band", [2000.0, 7000.0]) * np.exp(-t / 0.09)
	return x * v


# ─── Tema de Kalin (grados en tonalidad mayor) ──────────────────────────────

TEMA_A = "1:1.5 2:.5 3:1 5:1 | 6:1.5 5:.5 3:2 | 2:1 3:.5 2:.5 1:1 6,:1 | 1:3 r:1 | 1:1.5 2:.5 3:1 5:1 | 1':1.5 6:.5 5:2 | 6:1 5:.5 3:.5 2:1 3:1 | 1:3 r:1"
TEMA_B = "4:1.5 5:.5 6:1 1':1 | 6:1 5:1 3:2 | 4:1 5:.5 6:.5 5:1 3:1 | 2:3 r:1 | 3:1.5 5:.5 6:1 5:1 | 1':1.5 2':.5 1':2 | 6:1 5:.5 3:.5 2:1 3:.5 2:.5 | 1:3 r:1"
ACORDES_A = "1 4 2 1 1 6 2/5 1"
ACORDES_B = "4 1 4/5 5 1 6 4/5 1"

# Patrones reutilizables (tiempo, índice de nota del acorde, duración)
ARPEGIO_CORCHEAS = [(0, 0, .5), (.5, 1, .5), (1, 2, .5), (1.5, 1, .5), (2, 3, .5), (2.5, 2, .5), (3, 1, .5), (3.5, 2, .5)]
ARPEGIO_LENTO = [(0, 0, 1), (1, 1, 1), (2, 2, 1), (3, 3, 1)]
BAJO_UNO_TRES = [(0, 0, 1.5), (2, 4, 1.5)]


# ─── Piezas ──────────────────────────────────────────────────────────────────

def menu_principal() -> np.ndarray:
	"""Tema de Kalin completo: cálido, de bienvenida (Re mayor, 92 bpm)."""
	c = Cancion(92, 4, 32, 62, semilla=11)
	c.pista("melodia", 0.0, 0.25, -17)
	c.pista("flauta", 0.1, 0.3, -17)
	c.pista("contra", -0.35, 0.25, -24)
	c.pista("jarana", 0.4, 0.2, -25)
	c.pista("bajo", 0.0, 0.08, -21)
	c.pista("sonaja", 0.5, 0.15, -12, "pico")
	c.pista("tunkul", -0.2, 0.2, -9, "pico")
	acordes = " ".join([ACORDES_A, ACORDES_B, ACORDES_A, ACORDES_B])
	c.melodia("melodia", s.marimba, TEMA_A, 0, 1, tremolo=True)
	c.melodia("flauta", s.flauta, TEMA_B, 8, 1)
	c.melodia("flauta", s.flauta, TEMA_A, 16, 1)
	c.melodia("contra", s.marimba, TEMA_A, 16, 1, armonia=-2, vel=0.6)
	c.melodia("melodia", s.marimba, TEMA_B, 24, 1, tremolo=True)
	c.arpegio("contra", s.marimba, " ".join([ACORDES_B]), ARPEGIO_CORCHEAS, 8, 0, 0.45)
	c.arpegio("contra", s.marimba, ACORDES_B, ARPEGIO_LENTO, 24, 0, 0.45)
	c.rasgueo("jarana", acordes, [(0.5, "x"), (1, "D"), (1.5, "U"), (2.5, "x"), (3, "D"), (3.5, "U")])
	c.bajo("bajo", acordes, BAJO_UNO_TRES)
	c.ritmo("sonaja", sacudida, "..o...o...o...o.")
	c.ritmo("tunkul", lambda v: s.tunkul(110.0, round(v, 2)), "x.......x..o....|x.......x.......")
	return c.mezclar()


def intro_libro() -> np.ndarray:
	"""El libro de los portales: misterio suave (Si menor, 72 bpm)."""
	c = Cancion(72, 4, 16, 59, "menor", reverb_t60=3.2, reverb_brillo=0.7, semilla=12)
	c.pista("celesta", 0.25, 0.5, -22)
	c.pista("ocarina", -0.1, 0.45, -18)
	c.pista("colchon", 0.0, 0.5, -24)
	c.pista("lluvia", 0.0, 0.3, -30)
	acordes = "1 6 3 7 " * 4
	c.colchon("colchon", acordes, 0, 0, brillo=0.3)
	c.arpegio("celesta", s.campana, acordes, [(0, 0, 1), (.75, 2, 1), (1.5, 3, 1), (2.25, 4, 1), (3, 2, 1)], 0, 1, 0.5)
	c.melodia("ocarina", s.ocarina, "1:1.5 2:.5 3:1 5:1 | 6:2 1':2 | 3:1.5 5:.5 3:2 | 7,:3 r:1", 4, 1)
	c.melodia("ocarina", s.ocarina, "5:1.5 6:.5 5:1 3:1 | 1':2 6:2 | 5:1.5 3:.5 5:2 | 4:2 7,:2", 8, 1)
	for compas in (0, 8):
		c.poner("lluvia", compas * 4, palo_de_lluvia(3.0), humano=0)
	return c.mezclar(-21)


def huracan() -> np.ndarray:
	"""Cinemática del huracán: tambores graves y cadencia dramática (Re menor, 84 bpm)."""
	c = Cancion(84, 4, 16, 50, "menor", reverb_t60=2.8, reverb_brillo=0.35, semilla=13)
	c.pista("tambor", 0.0, 0.2, -6, "pico")
	c.pista("bombo", 0.0, 0.35, -5, "pico")
	c.pista("colchon", 0.0, 0.4, -21)
	c.pista("flauta", -0.15, 0.4, -18)
	c.pista("coro", 0.2, 0.6, -24)
	acordes = "1 7M 6 5M " * 4
	c.colchon("colchon", acordes, 0, 0, brillo=0.2)
	c.ritmo("tambor", lambda v: s.tambor(88.0, round(v, 2)), "x..o..x.x..o..o.", 0)
	c.ritmo("tambor", lambda v: s.tambor(130.0, round(v * 0.7, 2)), "....x.......x.xo", 8)
	c.ritmo("bombo", lambda v: s.bombo(48.0, round(v, 2)), "x...............|................", 0)
	c.melodia("flauta", s.flauta, "1:2 2:1 3:1 | 2:4 | 1:2 7,:1 6,:1 | 5,:4 | 1:2 2:1 3:1 | 4:2 3:2 | 1:2 7,:1 6,:1 | #7,:4", 4, 1, vel=0.75)
	c.colchon("coro", "1 7M 6 5M", 12, 1, instrumento=s.coro, vel=0.9, vocal="o")
	return c.mezclar(-19)


def orilla_isla() -> np.ndarray:
	"""Kalin despierta en la playa: descubrimiento tranquilo (La mayor, 84 bpm)."""
	c = Cancion(84, 4, 16, 57, semilla=14)
	c.pista("arpegio", -0.3, 0.3, -21)
	c.pista("flauta", 0.1, 0.35, -17)
	c.pista("marimba", 0.35, 0.3, -21)
	c.pista("bajo", 0.0, 0.1, -23)
	c.pista("colchon", 0.0, 0.4, -27)
	c.pista("sonaja", 0.4, 0.3, -18, "pico")
	acordes = "1 4 6 5 1 4 2 5 " * 2
	c.arpegio("arpegio", s.pulsada, acordes, [(0, 0, 1), (.5, 2, .5), (1, 3, .5), (1.5, 2, .5), (2, 4, .5), (2.5, 2, .5), (3, 3, .5), (3.5, 1, .5)], 0, 0, 0.55)
	c.melodia("flauta", s.flauta, "3:2 5:1 6:1 | 1':3 r:1 | 6:1.5 5:.5 3:1 2:1 | 2:3 r:1 | 3:2 5:1 6:1 | 1':2 6:2 | 6:1 5:1 3:1 2:1 | 5,:1 7,:1 2:2", 4, 1)
	c.arpegio("marimba", s.marimba, "1 4 6 5", ARPEGIO_LENTO, 12, 1, 0.5)
	c.bajo("bajo", acordes, [(0, 0, 3)])
	c.colchon("colchon", acordes, 0, 0, brillo=0.25)
	c.ritmo("sonaja", lambda v: s.sonaja(round(v, 2), 0.6, 3), "o.......|........|....o...|........")
	return c.mezclar(-20)


def sak_beh() -> np.ndarray:
	"""Mundo 1 · los caminos blancos: rompecabezas con ritmo (Sol mayor, 108 bpm)."""
	c = Cancion(108, 4, 16, 55, semilla=15)
	c.pista("ostinato", -0.25, 0.2, -21)
	c.pista("ocarina", 0.15, 0.3, -18)
	c.pista("flauta", -0.1, 0.3, -18)
	c.pista("bajo", 0.0, 0.08, -21)
	c.pista("tunkul", 0.0, 0.18, -8, "pico")
	c.pista("tunkul_agudo", 0.3, 0.18, -12, "pico")
	c.pista("sonaja", 0.45, 0.15, -13, "pico")
	c.pista("caparazon", -0.45, 0.2, -15, "pico")
	acordes = "1 6 4 5 " * 4
	c.arpegio("ostinato", s.marimba, acordes, [(0, 0, .5), (.5, 1, .5), (1, 2, .5), (1.5, 1, .5), (2, 3, .5), (2.5, 2, .5), (3, 1, .5), (3.5, 2, .5)], 0, 0, 0.55)
	llamada = "5:.5 6:.5 1':1 6:.5 5:.5 3:1 | 3:1.5 2:.5 3:2"
	c.melodia("ocarina", s.ocarina, llamada, 4, 1)
	c.melodia("ocarina", s.ocarina, llamada, 8, 1)
	c.melodia("flauta", s.flauta, "5:.5 6:.5 1':1 2':1 3':1 | 1':1.5 6:.5 5:1 3:1", 12, 1)
	c.bajo("bajo", acordes, [(0, 0, .9), (1, 4, .9), (2, 0, .9), (3, 4, .9)])
	c.ritmo("tunkul", lambda v: s.tunkul(98.0, round(v, 2)), "x.......x..x....")
	c.ritmo("tunkul_agudo", lambda v: s.tunkul(147.0, round(v, 2)), "....x.......x..o")
	c.ritmo("sonaja", sacudida, "..x...x...x...x.")
	c.ritmo("caparazon", lambda v: s.caparazon(1100.0, round(v, 2)), "...........x...x|................")
	return c.mezclar(-19)


def aldea_animales() -> np.ndarray:
	"""Capítulos con los animales: juguetón y saltarín (Fa mayor, 100 bpm)."""
	c = Cancion(100, 4, 16, 53, semilla=16)
	c.pista("clarinete", 0.1, 0.25, -17)
	c.pista("marimba", -0.3, 0.25, -21)
	c.pista("pulsada", 0.35, 0.2, -23)
	c.pista("bajo", 0.0, 0.08, -21)
	c.pista("caparazon", -0.4, 0.2, -12, "pico")
	c.pista("sonaja", 0.45, 0.15, -15, "pico")
	acordes = "1 4 5 1 1 4 5 1 4 4 1 1 2 5 1 5"
	c.melodia("clarinete", s.clarinete, "1:.5 3:.5 5:1 6:.5 5:.5 3:1 | 4:.5 6:.5 1':1 6:1 4:1 | 5:.5 7:.5 2':1 7:.5 5:.5 2:1 | 1:1 5,:1 1:1 r:1 | 1:.5 3:.5 5:1 6:.5 5:.5 3:1 | 4:.5 6:.5 1':1 6:1 4:1 | 5:.5 7:.5 2':1 7:.5 5:.5 2:1 | 1:3 r:1", 0, 1, legato=0.8)
	c.melodia("marimba", s.marimba, "6:1 6:.5 5:.5 4:1 6:1 | 1':2 6:2 | 5:1 5:.5 4:.5 3:1 5:1 | 1':2 5:2 | 2:1 4:1 6:1 4:1 | 5:1 7,:1 2:1 5:1 | 3:.5 2:.5 1:1 3:.5 2:.5 1:1 | 2:2 7,:1 5,:1", 8, 1, tremolo=True, vel=0.85)
	c.rasgueo("pulsada", acordes, [(1, "x"), (3, "x")], brillo=0.7)
	c.bajo("bajo", acordes, [(0, 0, .8), (2, 4, .8)])
	c.ritmo("caparazon", lambda v: s.caparazon(950.0, round(v, 2)), "....x.......x...")
	c.ritmo("sonaja", sacudida, "x.o.x.o.x.o.x.oo")
	return c.mezclar(-19)


def camino_solar() -> np.ndarray:
	"""Exploración al atardecer: vals tranquilo (Do mayor, 3/4, 80 bpm)."""
	c = Cancion(80, 3, 16, 60, semilla=17)
	c.pista("flauta", 0.0, 0.35, -17)
	c.pista("pulsada", 0.3, 0.3, -22)
	c.pista("bajo", -0.1, 0.1, -22)
	c.pista("colchon", 0.0, 0.4, -27)
	acordes = "1 6 4 5 1 6 2 5 4 1 4 5 6 4 2 5"
	c.melodia("flauta", s.flauta, "5:2 3:1 | 1:2 3:1 | 4:1 6:1 1':1 | 7:2 5:1 | 5:2 1':1 | 3':1.5 2':.5 1':1 | 6:2 4:1 | 5:3 | 6:1 1':1 6:1 | 5:2 3:1 | 4:1 6:1 1':1 | 2':2 7:1 | 1':1.5 7:.5 6:1 | 6:1 5:1 4:1 | 2:1 4:1 6:1 | 5:2 r:1", 0, 1)
	c.bajo("bajo", acordes, [(0, 0, 1)])
	c.arpegio("pulsada", s.pulsada, acordes, [(1, 1, .8), (1, 2, .8), (2, 1, .8), (2, 2, .8)], 0, 0, 0.5)
	c.colchon("colchon", acordes, 0, 0, brillo=0.2)
	return c.mezclar(-20)


def casa_vacia() -> np.ndarray:
	"""La casa maya vacía: melancolía (La menor, 64 bpm)."""
	c = Cancion(64, 4, 12, 57, "menor", reverb_t60=3.0, semilla=18)
	c.pista("flauta", 0.0, 0.45, -17)
	c.pista("colchon", 0.0, 0.5, -24)
	c.pista("marimba", 0.3, 0.45, -22)
	acordes = "1 6 4 5M 1 6 4 5M 1 6 4 5M"
	c.colchon("colchon", acordes, 0, 0, brillo=0.15)
	c.melodia("flauta", s.flauta, "5:2 3:1 1:1 | 3:3 1:1 | 4:2 6:1 4:1 | 5:3 r:1 | 1':2 7:1 5:1 | 6:2 1':2 | 4:1 3:1 2:1 4:1 | #7,:2 5,:2", 0, 1, vel=0.7)
	c.arpegio("marimba", s.marimba, "1 6 4 5M", [(0, 0, 1), (1.5, 2, 1), (2.5, 3, 1)], 8, 1, 0.45)
	return c.mezclar(-21)


def jarana_casa_maya() -> np.ndarray:
	"""Mundo 2 · la Casa Maya: estilo jarana yucateca en 3/4 (Sol mayor, 138 bpm)."""
	c = Cancion(138, 3, 32, 55, semilla=19)
	c.pista("clarinete", 0.15, 0.2, -17)
	c.pista("flauta", -0.2, 0.25, -18)
	c.pista("segunda", 0.35, 0.2, -21)
	c.pista("jarana", -0.4, 0.15, -21)
	c.pista("bajo", 0.0, 0.06, -20)
	c.pista("guiro", 0.45, 0.12, -14, "pico")
	c.pista("timbal", -0.2, 0.15, -10, "pico")
	frase = "1 1 5 5 5 5 1 1 1 1 4 4 1 5 1 1"
	acordes = frase + " " + frase
	melodia = "3:1 5:1 3:1 | 1:1 3:1 5:1 | 4:2 2:1 | 7,:1 2:1 4:1 | 6:1 5:1 4:1 | 2:1 7,:1 5,:1 | 1:1 3:1 5:1 | 1':2 r:1 | 5:1 6:1 5:1 | 3:1 1:1 3:1 | 4:1 6:1 1':1 | 6:2 4:1 | 5:1 3:1 1:1 | 2:1 4:1 2:1 | 1:1 3:1 2:1 | 1:2 r:1"
	c.melodia("clarinete", s.clarinete, melodia, 0, 1, legato=0.85)
	c.melodia("flauta", s.flauta, melodia, 16, 2, vel=0.7, legato=0.85)
	c.melodia("segunda", s.clarinete, melodia, 16, 1, armonia=-2, vel=0.7, legato=0.85)
	c.rasgueo("jarana", acordes, [(0, "D"), (1, "D"), (1.5, "U"), (2, "D"), (2.5, "U")], vel=0.6, brillo=0.65)
	c.bajo("bajo", acordes, [(0, 0, .9), (2, 4, .9)])
	c.ritmo("guiro", guiro, "x.o.o.")
	c.ritmo("timbal", lambda v: s.tambor(190.0, round(v, 2)), "......|....xx")
	return c.mezclar(-18)


def taller_adjetivos() -> np.ndarray:
	"""Mundo 3 · hechizos de adjetivos: taller juguetón (Do mayor, 104 bpm)."""
	c = Cancion(104, 4, 16, 60, semilla=20)
	c.pista("ocarina", 0.0, 0.3, -17)
	c.pista("marimba", -0.3, 0.25, -19)
	c.pista("clarinete", 0.2, 0.25, -18)
	c.pista("pulsada", 0.4, 0.15, -23)
	c.pista("bajo", 0.0, 0.06, -21)
	c.pista("claves", -0.45, 0.2, -13, "pico")
	acordes = "1 6 4 5 " * 4
	pregunta = "1:.5 1:.5 5:1 3:1 r:1 | 6,:.5 1:.5 3:1 6:1 r:1 | 4:.5 4:.5 1':1 6:1 r:1 | 5:.5 7:.5 2':1 5:1 r:1"
	respuesta = "3':.5 2':.5 1':1 5:1 r:1 | 1':.5 7:.5 6:1 3:1 r:1 | 6:.5 5:.5 4:1 1:1 r:1 | 2:.5 4:.5 5:1 7,:1 r:1"
	c.melodia("ocarina", s.ocarina, pregunta, 0, 1, legato=0.7)
	c.melodia("marimba", s.marimba, respuesta, 4, 1)
	c.melodia("clarinete", s.clarinete, pregunta, 8, 1, legato=0.6)
	c.melodia("marimba", s.marimba, respuesta, 12, 1)
	c.melodia("ocarina", s.ocarina, respuesta, 12, 1, vel=0.6, legato=0.7)
	c.arpegio("pulsada", s.pulsada, acordes, [(0, 0, .3), (1, 2, .3), (1.5, 1, .3), (2.5, 2, .3), (3, 1, .3)], 0, 0, 0.5)
	c.bajo("bajo", acordes, [(0, 0, .5), (1.5, 4, .5), (2, 0, .5), (3, 7, .5)])
	c.ritmo("claves", lambda v: s.caparazon(1500.0, round(v, 2)), "x..x..x...x.x...")
	return c.mezclar(-19)


def milpa_manana() -> np.ndarray:
	"""Exploración en la milpa: mañana luminosa en 6/8 (Re mayor)."""
	c = Cancion(186, 6, 16, 62, semilla=21)
	c.pista("flauta", 0.0, 0.3, -17)
	c.pista("marimba", 0.3, 0.3, -19)
	c.pista("jarana", -0.35, 0.2, -23)
	c.pista("bajo", 0.0, 0.08, -22)
	c.pista("sonaja", 0.45, 0.2, -16, "pico")
	acordes = "1 4 1 5 1 4 5 1 " * 2
	melodia = "5:2 6:1 5:2 3:1 | 4:3 6:3 | 5:2 1':1 3':3 | 2':3 7:2 5:1 | 5:2 6:1 5:2 3:1 | 4:2 6:1 1':3 | 7:2 6:1 5:2 2:1 | 1:5 r:1"
	c.melodia("flauta", s.flauta, melodia, 0, 1)
	c.melodia("marimba", s.marimba, melodia, 8, 1, tremolo=True)
	c.melodia("flauta", s.flauta, "r:6 | r:6 | r:3 5:.5 6:.5 5:2 | r:6 | r:6 | r:3 1':.5 2':.5 1':2 | r:6 | r:6", 8, 2, vel=0.45)
	c.rasgueo("jarana", acordes, [(0, "D"), (2, "U"), (3, "D"), (5, "U")], vel=0.5)
	c.bajo("bajo", acordes, [(0, 0, 2.5), (3, 4, 2.5)])
	c.ritmo("sonaja", sacudida, "x.ox.o")
	return c.mezclar(-20)


def cocina_aldea() -> np.ndarray:
	"""Mundo 4 · yo quiero: fiesta de la comida (Fa mayor, 116 bpm)."""
	c = Cancion(116, 4, 16, 53, semilla=22)
	c.pista("marimba", 0.0, 0.25, -17)
	c.pista("segunda", 0.3, 0.25, -21)
	c.pista("clarinete", -0.25, 0.25, -21)
	c.pista("bajo", 0.0, 0.06, -20)
	c.pista("sonaja", 0.45, 0.15, -14, "pico")
	c.pista("tunkul", -0.2, 0.18, -9, "pico")
	acordes = "1 4 5 1 1 4 5 1 4 4 1 1 2 5 1 1"
	melodia = "5:1 3:.5 5:.5 1':1 5:1 | 6:1 4:.5 6:.5 1':1 6:1 | 7:1 5:.5 7:.5 2':1 7:1 | 1':2 r:2 | 5:1 3:.5 5:.5 1':1 5:1 | 6:1 4:.5 6:.5 1':1 6:1 | 7:1 5:.5 7:.5 2':1 7:1 | 1':1 5:1 1:2 | 4:1 6:1 1':1 6:1 | 4':1 3':.5 2':.5 1':2 | 5:1 1':1 3':1 1':1 | 5:2 r:2 | 2':1 1':.5 7:.5 6:1 4:1 | 5:1 7:1 2':1 7:1 | 1':1 5:1 3:1 5:1 | 1:2 r:2"
	c.melodia("marimba", s.marimba, melodia, 0, 1, tremolo=True)
	c.melodia("segunda", s.marimba, melodia, 0, 1, armonia=-2, vel=0.6, tremolo=True)
	c.colchon("clarinete", acordes, 8, 0, instrumento=s.clarinete, vel=0.35)
	c.bajo("bajo", acordes, [(0, 0, .5), (1, 2, .5), (2, 4, .5), (3, 2, .5)])
	c.ritmo("sonaja", sacudida, "xooxxooxxooxxoxo")
	c.ritmo("tunkul", lambda v: s.tunkul(115.0, round(v, 2)), "x.....x.x.......|x.....x.x...x.o.")
	return c.mezclar(-18)


def tianguis() -> np.ndarray:
	"""Mundo 4 · las piedras que cuentan: tianguis alegre con un motivo que sube
	de uno en uno, como quien cuenta (Sol mayor, 104 bpm)."""
	c = Cancion(104, 4, 16, 55, semilla=31)
	c.pista("marimba", -0.1, 0.25, -17)
	c.pista("ocarina", 0.25, 0.3, -20)
	c.pista("jarana", -0.35, 0.2, -22)
	c.pista("bajo", 0.0, 0.06, -20)
	c.pista("sonaja", 0.45, 0.15, -15, "pico")
	c.pista("tunkul", -0.2, 0.18, -9, "pico")
	acordes = "1 4 5 1 1 4 2/5 1 6 4 5 1 4 1 2/5 1"
	# Uno, dos, tres, cuatro, cinco: la escala sube grado por grado y responde.
	melodia = "1:.5 2:.5 3:.5 4:.5 5:2 | 6:1 5:1 4:1 3:1 | 2:.5 3:.5 4:.5 5:.5 6:1 5:1 | 3:2 r:2 | 1:.5 2:.5 3:.5 4:.5 5:2 | 1':1 7:.5 6:.5 5:2 | 4:1 6:1 5:1 2:1 | 1:2 r:2 | 3:1 3:.5 4:.5 5:1 5:1 | 6:1 1':1 6:2 | 5:1 5:.5 4:.5 3:1 2:1 | 3:2 r:2 | 1:.5 2:.5 3:.5 4:.5 5:1 1':1 | 7:1 6:1 5:2 | 2:1 4:1 3:1 2:1 | 1:2 r:2"
	c.melodia("marimba", s.marimba, melodia, 0, 1, tremolo=True)
	c.melodia("ocarina", s.ocarina, "5:2 6:2 | 5:4 | 4:2 3:2 | 1:4 | 5:2 6:2 | 1':4 | 6:2 5:2 | 3:4", 8, 1, vel=0.5)
	c.arpegio("jarana", s.pulsada, acordes, ARPEGIO_CORCHEAS, 0, 0, 0.4)
	c.bajo("bajo", acordes, BAJO_UNO_TRES)
	c.ritmo("sonaja", sacudida, "x.oxx.oxx.oxx.ox")
	c.ritmo("tunkul", lambda v: s.tunkul(120.0, round(v, 2)), "x.......x.x.....|x.......x...o...")
	return c.mezclar(-19)


def camino_portal() -> np.ndarray:
	"""Camino al portal: asombro y amanecer (Mi lidio, 80 bpm)."""
	c = Cancion(80, 4, 16, 64, "lidio", reverb_t60=3.0, reverb_brillo=0.75, semilla=23)
	c.pista("celesta", 0.3, 0.45, -21)
	c.pista("ocarina", -0.1, 0.4, -17)
	c.pista("colchon", 0.0, 0.45, -23)
	c.pista("coro", 0.0, 0.6, -24)
	c.pista("bajo", 0.0, 0.1, -24)
	acordes = "1 2 6 5 " * 4
	c.arpegio("celesta", s.campana, acordes, [(t * .5, i, .5) for t, i in enumerate([0, 1, 2, 3, 4, 3, 2, 1])], 0, 1, 0.45)
	c.colchon("colchon", acordes, 0, 0, brillo=0.35)
	melodia = "1:1 3:1 5:2 | 2:1 4:1 6:2 | 3':2 1':1 6:1 | 7:2 5:2 | 5:1 1':1 3':2 | 2':1 6:1 4:2 | 6:1 1':1 3':1 1':1 | 5:3 r:1"
	c.melodia("ocarina", s.ocarina, melodia, 0, 1)
	c.melodia("ocarina", s.ocarina, melodia, 8, 1, vel=0.7)
	c.melodia("celesta", s.campana, melodia, 8, 2, vel=0.5)
	c.colchon("coro", "1 2 6 5 1 2 6 5", 8, 1, instrumento=s.coro, vel=0.8, vocal="u")
	c.bajo("bajo", acordes, [(0, 0, 3.5)])
	return c.mezclar(-20)


def portal_regreso() -> np.ndarray:
	"""Mundo 5 · el portal de regreso: magia con determinación (Re menor, 96 bpm)."""
	c = Cancion(96, 4, 16, 50, "menor", reverb_t60=2.6, reverb_brillo=0.6, semilla=24)
	c.pista("campana", 0.1, 0.35, -17)
	c.pista("ostinato", -0.3, 0.2, -21)
	c.pista("colchon", 0.0, 0.4, -23)
	c.pista("coro", 0.0, 0.55, -25)
	c.pista("bajo", 0.0, 0.06, -20)
	c.pista("tambor", 0.0, 0.2, -8, "pico")
	c.pista("sonaja", 0.45, 0.15, -15, "pico")
	acordes = "1 7 6 7 " * 4
	c.arpegio("ostinato", s.marimba, acordes, [(t * .5, i, .5) for t, i in enumerate([0, 2, 1, 2, 3, 2, 1, 2])], 0, 1, 0.5)
	c.colchon("colchon", acordes, 0, 0, brillo=0.4)
	melodia = "1':1 5:1 3:1 5:1 | 7:1 2':1 4':1 2':1 | 6:1 1':1 3':1 1':1 | 2':2 7:2 | 3':1.5 2':.5 1':2 | 4':1.5 3':.5 2':2 | 1':1 3':1 6:1 1':1 | 7:3 r:1"
	c.melodia("campana", s.campana, melodia, 0, 1)
	c.melodia("campana", s.flauta, melodia, 8, 1, vel=0.75)
	c.colchon("coro", "1 7 6 7 1 7 6 7", 8, 0, instrumento=s.coro, vel=0.8, vocal="a")
	c.bajo("bajo", acordes, [(0, 0, .9), (1.5, 0, .4), (2, 4, .9), (3, 7, .9)])
	c.ritmo("tambor", lambda v: s.tambor(100.0, round(v, 2)), "x.....x...x.....", 0, 8)
	c.ritmo("tambor", lambda v: s.tambor(100.0, round(v, 2)), "x..o..x.x.x..o.o", 8, 8)
	c.ritmo("sonaja", sacudida, "..o...o...o...o.", 8, 8)
	return c.mezclar(-19)


def despedida() -> np.ndarray:
	"""Capítulo 9 · despedida: tema de Kalin, tierno (Sol mayor, 72 bpm)."""
	c = Cancion(72, 4, 16, 55, reverb_t60=2.6, semilla=25)
	c.pista("flauta", 0.0, 0.4, -17)
	c.pista("ocarina", 0.1, 0.4, -18)
	c.pista("pulsada", -0.3, 0.3, -21)
	c.pista("colchon", 0.0, 0.45, -26)
	c.pista("bajo", 0.0, 0.1, -23)
	acordes = ACORDES_A + " " + ACORDES_B
	c.melodia("flauta", s.flauta, TEMA_A, 0, 1, vel=0.75)
	c.melodia("ocarina", s.ocarina, TEMA_B, 8, 1, vel=0.75)
	c.arpegio("pulsada", s.pulsada, acordes, ARPEGIO_CORCHEAS, 0, 0, 0.45)
	c.colchon("colchon", acordes, 0, 0, brillo=0.2)
	c.bajo("bajo", acordes, [(0, 0, 1.8), (2, 4, 1.8)])
	return c.mezclar(-20)


def regreso_casa() -> np.ndarray:
	"""Cinemática final: el tema de Kalin como canción de cuna (Re mayor, 66 bpm)."""
	c = Cancion(66, 4, 16, 62, reverb_t60=3.2, reverb_brillo=0.6, semilla=26)
	c.pista("celesta", 0.15, 0.5, -18)
	c.pista("marimba", -0.25, 0.4, -20)
	c.pista("colchon", 0.0, 0.5, -24)
	c.pista("bajo", 0.0, 0.12, -24)
	acordes = ACORDES_A + " " + ACORDES_B
	c.melodia("celesta", s.campana, TEMA_A, 0, 1, vel=0.7)
	c.melodia("marimba", s.marimba, TEMA_B, 8, 1, tremolo=True, vel=0.7)
	c.arpegio("marimba", s.marimba, ACORDES_A, [(0, 0, 1), (1, 2, 1), (2, 3, 1), (3, 2, 1)], 0, 0, 0.35)
	c.colchon("colchon", acordes, 0, 0, brillo=0.25)
	c.bajo("bajo", acordes, [(0, 0, 3.5)])
	return c.mezclar(-21)


def palo_de_lluvia(duracion: float) -> np.ndarray:
	"""Palo de lluvia: cascada de semillas que sube y baja."""
	n = s.segundos(duracion)
	rng = np.random.default_rng(77)
	x = np.zeros(n)
	densidad = np.sin(np.linspace(0, np.pi, n)) ** 1.5
	posiciones = np.nonzero(rng.random(n) < densidad * 0.004)[0]
	for p in posiciones:
		grano = rng.uniform(-1, 1, s.segundos(0.002)) * rng.uniform(0.2, 1.0)
		fin = min(p + len(grano), n)
		x[p:fin] += grano[: fin - p]
	return s.filtro(x, "band", [2500.0, 9000.0]) * 0.8


PIEZAS = {
	"musica_menu_principal": menu_principal,
	"musica_intro_libro": intro_libro,
	"musica_huracan": huracan,
	"musica_orilla_isla": orilla_isla,
	"musica_sak_beh": sak_beh,
	"musica_aldea_animales": aldea_animales,
	"musica_camino_solar": camino_solar,
	"musica_casa_vacia": casa_vacia,
	"musica_jarana_casa_maya": jarana_casa_maya,
	"musica_taller_adjetivos": taller_adjetivos,
	"musica_milpa_manana": milpa_manana,
	"musica_cocina_aldea": cocina_aldea,
	"musica_tianguis": tianguis,
	"musica_camino_portal": camino_portal,
	"musica_portal_regreso": portal_regreso,
	"musica_despedida": despedida,
	"musica_regreso_casa": regreso_casa,
}
