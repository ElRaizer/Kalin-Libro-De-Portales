"""Genera todo el audio del juego en res://Audio/.

Uso (desde la raíz del proyecto):
	python tools/generar_audio/generar.py            # todo
	python tools/generar_audio/generar.py efectos    # solo una carpeta
	python tools/generar_audio/generar.py musica_sak_beh acierto   # archivos sueltos

Requiere Python 3.10+, numpy, scipy y ffmpeg con libvorbis.
"""
from __future__ import annotations

import math
import sys
import time
from pathlib import Path

import numpy as np

import ambientes
import efectos
import musica
import sintesis as s

RAIZ = Path(__file__).resolve().parents[2] / "Audio"


def _informe(nombre: str, x: np.ndarray, inicio: float) -> None:
	x = s.a_estereo(x)
	rms = 20 * math.log10(math.sqrt(float(np.mean(x ** 2))) or 1e-9)
	pico = 20 * math.log10(float(np.max(np.abs(x))) or 1e-9)
	print(f"  {nombre:34s} {len(x) / s.SR:6.1f} s   pico {pico:6.1f} dB   rms {rms:6.1f} dB   ({time.time() - inicio:4.1f} s)")


def generar_musica(filtro: set[str]) -> None:
	print("Música → Audio/musica")
	for nombre, funcion in musica.PIEZAS.items():
		if filtro and nombre not in filtro and "musica" not in filtro:
			continue
		inicio = time.time()
		x = funcion()
		s.guardar_ogg(x, RAIZ / "musica" / f"{nombre}.ogg", 4.0)
		_informe(nombre, x, inicio)


def generar_ambientes(filtro: set[str]) -> None:
	print("Ambientes → Audio/ambiente")
	for nombre, funcion in ambientes.AMBIENTES.items():
		if filtro and nombre not in filtro and "ambiente" not in filtro:
			continue
		inicio = time.time()
		x = funcion()
		s.guardar_ogg(x, RAIZ / "ambiente" / f"{nombre}.ogg", 3.0)
		_informe(nombre, x, inicio)


def generar_efectos(filtro: set[str]) -> None:
	print("Efectos → Audio/efectos")
	for nombre, (funcion, sonoridad_db) in efectos.EFECTOS.items():
		if filtro and nombre not in filtro and "efectos" not in filtro:
			continue
		inicio = time.time()
		x = s.a_estereo(funcion())
		x = s.normalizar_sonoridad(x, sonoridad_db)
		x = s.final_suave(x.copy(), 15.0)
		s.guardar_ogg(x, RAIZ / "efectos" / f"{nombre}.ogg", 5.0)
		_informe(nombre, x, inicio)


if __name__ == "__main__":
	pedidos = set(sys.argv[1:])
	generar_musica(pedidos)
	generar_ambientes(pedidos)
	generar_efectos(pedidos)
