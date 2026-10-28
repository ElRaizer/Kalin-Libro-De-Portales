# Variación entre partidas

Las actividades varían desde el primer intento. La historia mantiene su orden y
las primeras demostraciones conservan su sencillez: la primera unión es recta y
corta, el primer hechizo del taller conserva su ejemplo y comida empieza sin tamaño.

## Preguntas y situaciones

- Los siete momentos de reconocimiento de animales eligen entre los animales
  presentes que el recorrido ya ha presentado. El personaje que pregunta no es
  el objetivo. La plantilla `question_template` cambia el nombre en todo el texto
  junto con `target_word`. Los recursos de autor no se modifican.
- La casa mezcla por separado presentación y recuerdo. Cada fase cubre todos sus
  objetos. El taller y comida conservan el primer ejemplo y mezclan el resto de
  la práctica en episodios de hasta tres retos. Cada grupo va seguido del recuerdo
  de esos mismos retos antes de introducir el siguiente grupo. Se mantiene una
  presentación y una recuperación por reto; cuando hay más de uno, el recuerdo
  no empieza repitiendo el último ejemplo. Los planes completos ya guardados
  conservan su orden al continuar.
- Cada paseo ofrece dos necesidades por personaje, con respuestas entre sus
  tres tarjetas. Las tres se eligen conjuntamente para evitar repetir objetos y
  se mezcla el orden de los personajes. Los encargos aplican el mismo criterio,
  conservando la prioridad de aprendizaje cuando las opciones no se repiten.
  `alternate_task` permite revisar la alternativa desde el Inspector.
  Volver a un paseo completado ofrece otro conjunto. Al continuar se conservan las
  peticiones abiertas o resueltas; se pueden ajustar las que aún no se han presentado
  para retirar repeticiones de una partida anterior.
- El portal tiene cuatro bancos: cuatro presentaciones de animales, cinco
  objetos, seis combinaciones de objeto y cualidad y seis peticiones. Usa las
  frases ya presentes en el catálogo y los ejercicios. Elige una pregunta de
  cada banco y mezcla esas cuatro páginas; conserva después el bloque de
  expresiones de saludo, agradecimiento y despedida.
- El taller final conserva su selección de encargos según la práctica registrada.

Cada intento guarda su semilla y sus decisiones concretas: preguntas, planes,
variante del tablero, necesidades y páginas del portal. Consultar el libro,
abrir el menú o continuar desde JSON conserva el reto pendiente. El botón
**Repetir** inicia otro intento y evita reutilizar inmediatamente la misma
pregunta de animal, variante de tablero, orden de práctica o selección del portal.
Reiniciar completamente la partida borra también esta referencia anterior.

## Tableros: catálogo de 48 variantes

Hay doce geometrías por nivel. No se colocan rocas al azar durante la partida.
Cada variante incluye un testigo con tres rutas completas, adyacentes y sin
casillas compartidas, incluidos orígenes y destinos. El juego comprueba ese
testigo antes de aplicar el diseño. Los nodos visuales guardados se recolocan;
no se generan nodos del tablero durante la partida.

| Criterio | Límite |
| --- | --- |
| Tamaño y parejas | 12 × 7; tres parejas |
| Rocas | Misma cantidad que el diseño original de cada nivel |
| Primera unión del nivel 1 | Cuatro pasos, cero giros |
| Nivel 1 completo | Hasta 29 pasos; hasta dos giros por ruta |
| Pasos totales, niveles 2–4 | Diferencia de hasta cuatro respecto al testigo original |
| Giros totales, niveles 2–4 | Diferencia de hasta cuatro respecto al testigo original |
| Máximo de pasos o giros por ruta, niveles 2–4 | Hasta dos más que el máximo original |

Estos son criterios geométricos de dificultad comparable. La dificultad percibida
y la comprensión de las variantes quedan pendientes de pruebas con el público
objetivo. Los retos de observar rocas y recordar destinos siguen funcionando.

El catálogo vive en `scripts/features/grid_paths/data/grid_variant_catalog.gd`, que se incluye mediante
las dependencias normales de Godot al exportar. Se regenera de forma determinista:

```powershell
python tools/build_grid_variants.py
```

Si cambia la geometría del tablero de autor, las variantes de ese nivel no se
aplican hasta regenerar el catálogo. El Inspector permite desactivar `vary_board`
o `vary_challenges` para trabajar con el tablero o portal originales.

## Compatibilidad y comprobaciones

Las visitas a la aldea seleccionan también tres habitantes distintos entre los doce
animales presentados. Cada uno conserva su casa; otros tres vecinos diferentes pueden
saludar desde el camino. El reparto queda en `residents`, se mantiene al continuar y
participa en `previous_variation` al repetir. Reanudar conserva los dueños
de las peticiones vigentes. La despedida mantiene sus destinatarios narrativos.

El único guardado vigente conserva preguntas, geometría, planes y necesidades
de cada intento. Repetir genera una variación nueva. No se atribuye recuerdo
independiente a una respuesta restaurada ni a una elección con tarjetas.
Los formatos retirados se rechazan y requieren reiniciar la partida.

`tests/validate_replayability.gd`, incluida en `tools/validate.ps1`, resuelve los
48 tableros con el controlador real, comprueba posiciones visibles, métricas,
preguntas, alternativas, fases, JSON, restauración y la acción Repetir. Puede
generar capturas con el renderizador real:

```powershell
godot_console.exe --path . --script res://tests/validate_replayability.gd -- --capture=C:/ruta/a/capturas
```

## Combinaciones de objeto y cualidad

`combination_catalog.gd` declara 28 combinaciones permitidas, además de nueve
peticiones sin cualidad. No se utiliza el producto cartesiano de todas las palabras.

| Objetos | Cualidades | Combinaciones |
| --- | --- | ---: |
| Mesa, silla y hamaca | pequeña, grande, bonita, fuerte | 12 |
| Plato | pequeño, grande, bonito | 3 |
| Plátano, fruta y calabaza | pequeño, grande, bonito, delicioso | 12 |
| Comida | deliciosa | 1 |

Agua conserva su petición simple. Se excluyen cualidades como deliciosa para muebles,
fuerte para alimentos y las combinaciones que requieren un contexto adicional.

Taller y Yo quiero seleccionan seis peticiones al comenzar un intento. Cada petición
conserva una recuperación; se añade presentación guiada cuando contiene palabras
todavía no conocidas. El plan completo se guarda y no cambia al reanudar.
El taller mantiene una silla fuerte como
primer ejemplo y cubre las cinco cualidades; los demás ejemplos varían. Comida cubre
sus cinco alimentos, incluyendo agua sin cualidad. Los tres encargos de cada visita
usan objetos distintos. Las semillas y la evidencia de recuerdo distribuyen los
pedidos; no se exige completar las 28 combinaciones en una partida.

`combination_plan`, `combination_animals` y `combination_tasks` guardan las
selecciones vigentes de cada actividad. Al repetir se elige otro conjunto. El portal guarda en `portal_pool_keys` su selección
de combinaciones practicadas, para no exigir un ejemplo nuevo en la recapitulación.
El reparto se realiza localmente, sin coordinación entre dispositivos.

`validate_combinations.gd` comprueba 128 semillas por capítulo, cobertura de las 28
combinaciones, 256 selecciones de aldea, opciones correctas, entrega de encargos,
compatibilidad JSON, recapitulación y presentación móvil. Forma parte de las suites descubiertas por el ejecutor.
