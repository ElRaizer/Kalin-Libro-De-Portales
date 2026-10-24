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
  la práctica; sus fases de recuerdo cubren todas las preguntas en otro orden y
  no empiezan repitiendo la última de la práctica.
- Cada paseo ofrece dos necesidades por personaje, con respuestas entre sus
  tres tarjetas. Se elige una por personaje y se mezcla el orden de los tres.
  `alternate_task` permite revisar la alternativa desde el Inspector.
  Volver a un paseo completado ofrece otro conjunto; uno pendiente se conserva.
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

El catálogo vive en `scripts/data/GridVariantCatalog.gd`, que se incluye mediante
las dependencias normales de Godot al exportar. Se regenera de forma determinista:

```powershell
python tools/build_grid_variants.py
```

Si cambia la geometría del tablero de autor, las variantes de ese nivel no se
aplican hasta regenerar el catálogo. El Inspector permite desactivar `vary_board`
o `vary_challenges` para trabajar con el tablero o portal originales.

## Compatibilidad y comprobaciones

Los guardados anteriores conservan sus preguntas pendientes, geometría original,
planes y necesidades. Al repetir se activa la variación nueva. No se atribuye a
recuerdo independiente una respuesta restaurada o una elección con tarjetas.
El archivo pasa a versión 4 para que una edición antigua del juego no intente
interpretar trazos nuevos sobre la geometría anterior.

`tests/validate_replayability.gd`, incluida en `tools/validate.ps1`, resuelve los
48 tableros con el controlador real, comprueba posiciones visibles, métricas,
preguntas, alternativas, fases, JSON, compatibilidad y la acción Repetir. Puede
generar capturas con el renderizador real:

```powershell
godot_console.exe --path . --script res://tests/validate_replayability.gd -- --capture=C:/ruta/a/capturas
```
