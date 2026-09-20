# Vocabulario y normalización ortográfica

Este archivo registra las grafías usadas por el juego. La referencia ortográfica general es la [Norma de escritura para la lengua maya del INALI](https://site.inali.gob.mx/Micrositios/normas/maya), complementada con el [Diccionario Maya de la Universidad Autónoma de Yucatán](https://www.mayas.uady.mx/diccionario/).

## Criterio del proyecto

- Los textos visibles usan una grafía canónica única.
- El código utiliza el apóstrofo ASCII `'` para representar el cierre glotal y evitar diferencias técnicas entre caracteres tipográficos.
- Las claves antiguas se migran automáticamente al cargar una partida.
- Los nombres de audio eliminan acentos y apóstrofos, pero la interfaz conserva la grafía completa.
- Se mantiene el vocabulario y el significado pedagógico definidos por el GDD. Las observaciones lexicográficas que cambian esos significados se documentan, pero no sustituyen el contenido sin una revisión posterior del GDD.

## Normalizaciones realizadas

| Variante anterior | Grafía adoptada | Nota |
|---|---|---|
| `Míis` | `Miis` | Gato |
| `Káax` | `Kaax` | Gallina |
| `Aak'` / `Áak'` | `Áak` | Tortuga |
| `K'uum` | `K'úum` | Calabaza; confirmada para el proyecto |
| `Ja'as` | `ja'as` | Plátano; se normalizó la mayúscula en listas y frases internas |
| `T'uut` | `T'uut'` | Loro; entrada reservada para contenido futuro |

Las palabras `Peek'`, `Kéej`, `K'éek'en`, `Ma'ax`, `Báalam`, `Kuuts`, `T'u'ul`, `Kay` y `Ch'íich'` ya coinciden con la escritura adoptada.

## Vocabulario por mundo

| Mundo | Nivel | Vocabulario |
|---:|---:|---|
| 1 | 1 | `Peek'`, `Miis`, `Kaax` |
| 1 | 2 | `Kéej`, `K'éek'en`, `Ma'ax` |
| 1 | 3 | `Báalam`, `Kuuts`, `T'u'ul` |
| 1 | 4 | `Kay`, `Ch'íich'`, `Áak` |
| 2 | 1 | `mayak`, `lak`, `ch'áak`, `chan`, `janal` |
| 3 | 1 | `mejen`, `nojoch`, `Jats'uts`, `ki'`, `jach'` |
| 4 | 1 | `ja'`, `ja'as`, `pak'al`, `K'úum` |
| 5 | 1 | `Bix a beel`, `Yuum bo'otik`, `Ka xi'ik tech jats'uts`, `Tak ti' uláak' k'iin` |

`Jats'uts` y `jach'` se incorporaron al Mundo 3 durante la reconstrucción de su
mecánica de sustantivos y adjetivos. `T'uut'` permanece en el catálogo para
contenido futuro, no se enseña en una escena jugable y no cuenta para completar
el Libro de Hechizos.

Las frases de cortesía del Mundo 5 se tomaron inicialmente del Prontuario de
frases de cortesía en maya del INALI. Deben revisarse con una persona hablante
antes de grabar su pronunciación o considerar definitivo el contenido.

## Decisiones conservadas del GDD

La consulta lexicográfica produjo observaciones de significado para `ch'áak`, `chan`, `pak'al` y `jach'`. Por decisión del proyecto, se conservan las asociaciones del GDD:

| Palabra del GDD | Significado conservado en el juego |
|---|---|
| `ch'áak` | Cama |
| `chan` | Silla |
| `pak'al` | Fruta |
| `jach'` | Fuerte |

Estas cuatro entradas deben revisarse junto con el GDD y una persona especialista antes de presentar el juego como material lingüístico validado. La UADY documenta, por ejemplo, `k'áanche'` para silla, `ich` para fruta y otras formas para fuerte; no se aplicaron esos cambios porque alterarían el vocabulario pedagógico solicitado.

## Recomendación para futuras incorporaciones

Antes de agregar una palabra nueva:

1. Confirmar grafía, significado y contexto de uso con al menos una fuente institucional.
2. Validar la frase completa, no solo la palabra aislada.
3. Registrar una única clave en `GameManager.VOCABULARY`.
4. Agregar alias solamente si una versión anterior ya pudo quedar guardada.
5. Validar pronunciación y audio con una persona hablante de maya yucateco.
