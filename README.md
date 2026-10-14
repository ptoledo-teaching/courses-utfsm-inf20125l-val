# VAL: Análisis de memoria con Valgrind

## Introducción

Este laboratorio introduce la detección automática de problemas de memoria en programas escritos en C mediante Valgrind y su herramienta Memcheck. El trabajo se concentra en problemas que no siempre provocan un cierre inesperado ni un resultado evidentemente incorrecto, como el uso de memoria no inicializada y la memoria dinámica que no se libera al finalizar el programa.

El laboratorio comienza con un ejemplo guiado sobre el uso de un valor no inicializado. Luego se analiza un programa más extenso cuya salida funcional es correcta, aunque su manejo de memoria no lo sea. Los test cases funcionales y las ejecuciones con Valgrind se utilizan en conjunto, ya que cada herramienta comprueba una propiedad distinta del programa.

### Prerrequisitos

- Tener iniciada la máquina virtual Lubuntu y haber clonado este repositorio.
- Tener disponibles `gcc`, `valgrind`, `diff`, `bash` y `chmod`.
- Manejar el uso de la terminal, la compilación en C, los test cases, las trazas de depuración y GDB.

### Objetivo general

- Detectar, interpretar y corregir problemas de manejo de memoria en programas escritos en C mediante Valgrind.

### Objetivos específicos

- Compilar programas con información de depuración y sin optimizaciones.
- Ejecutar programas mediante Memcheck.
- Identificar el uso de memoria no inicializada.
- Utilizar `--track-origins=yes` para encontrar el origen de un valor indefinido.
- Distinguir las categorías de memoria no liberada que informa Valgrind.
- Comprobar tanto el comportamiento funcional como la liberación de la memoria reservada.

### Estructura inicial

```text
workspace/
├── code/
│   ├── memory_example.c
│   └── squadron_registry.c
├── scripts/
│   ├── check.sh
│   ├── tests-run.sh
│   └── valgrind-run.sh
└── tests/
    ├── test001.in
    ├── test001.expected
    └── ...
```

- `memory_example.c` contiene el ejemplo guiado para observar el uso de memoria no inicializada.
- `squadron_registry.c` contiene el programa principal que se analizará durante el laboratorio.
- `tests-run.sh` comprueba la salida funcional del programa principal.
- `valgrind-run.sh` ejecuta los mismos test cases mediante Valgrind.
- `check.sh` permite revisar las actividades realizadas en el workspace.

## Contexto

La Alianza Rebelde mantiene un registro de los escuadrones asignados a sus operaciones. Cada entrada almacena el nombre de una unidad, su cantidad de misiones completadas y su tasa de éxito.

Con la información disponible, el programa genera un informe que indica cuántas unidades fueron procesadas, determina la cantidad total de misiones, calcula el promedio de sus tasas de éxito e identifica la unidad con mejor desempeño. El programa también prepara información interna de auditoría mediante memoria dinámica.

## Actividad

### 1. Preparación del workspace

#### 1.1. Entrar al directorio de trabajo

Ir a `workspace` y revisar su contenido:

```bash
cd workspace
ls
```

Los comandos de las siguientes secciones consideran que el directorio actual es `workspace`.

#### 1.2. Compilar para analizar la memoria

Construir los comandos necesarios para compilar ambos programas con `-Wall`, `-Wextra`, `-Werror`, `-std=c11`, `-g` y `-O0`:

- Compilar `code/memory_example.c` y generar `code/memory_example`.
- Compilar `code/squadron_registry.c` y generar `code/squadron_registry`.

Las flags adicionales son relevantes para el análisis:

- `-g` incorpora información que permite relacionar el ejecutable con sus funciones y líneas de código
- `-O0` desactiva las optimizaciones para facilitar la relación entre la ejecución y el código fuente

Las optimizaciones son transformaciones que el compilador aplica sobre el código máquina para mejorar el rendimiento. Pueden eliminar variables, cambiar el orden de algunas instrucciones o descartar código cuyo resultado no se utiliza. Valgrind puede analizar programas optimizados, pero un ejecutable sin optimizaciones produce información más fácil de interpretar mientras se aprende a utilizar la herramienta.

### 2. Ejemplo guiado: memoria no inicializada

#### 2.1. Observar la ejecución normal

El programa `memory_example` contiene tres valores enteros definidos directamente en su código y los almacena en un arreglo dinámico durante la ejecución. El programa recibe un único argumento: el umbral utilizado para comparar esos valores. No solicita valores adicionales mediante `stdin`; solamente informa cuántos de los tres valores se encuentran bajo el umbral.

Ejecutar el ejemplo con un umbral de `5`:

```bash
./code/memory_example 5
```

El programa puede imprimir un resultado razonable y terminar normalmente. Eso no demuestra que todos los valores utilizados durante la ejecución hayan sido inicializados correctamente.

#### 2.2. Ejecutar el programa con Valgrind

Analizar la misma ejecución mediante Valgrind:

```bash
valgrind ./code/memory_example 5
```

El informe debería incluir un mensaje similar a `Conditional jump or move depends on uninitialised value(s)`. Esto significa que una decisión del programa depende de una zona de memoria que no recibió un valor definido.

#### 2.3. Encontrar el origen

Repetir el análisis solicitando información sobre el origen de los valores indefinidos:

```bash
valgrind --track-origins=yes ./code/memory_example 5
```

La opción `--track-origins=yes` hace que el análisis sea más lento, pero agrega información sobre el lugar en que se reservó la memoria no inicializada. Utilizar la función y la línea informadas para revisar el código fuente con Vim.

Corregir el problema, volver a compilar con las mismas flags utilizadas en 1.2 y repetir el análisis. El ejemplo está corregido cuando imprime `Alertas detectadas: 2` y Valgrind no informa errores.

### 3. Análisis del programa

#### 3.1. Revisar la interfaz y ejecutar un test case

Cada entrada del programa a analizar comienza con la cantidad de unidades que se ingresarán. Las líneas siguientes contienen el nombre de una unidad, su cantidad de misiones completadas y su tasa de éxito:

```text
3
Howlrunner 12 97
Mauler 7 91
Backstabber 5 95
```

El programa genera un resumen con cuatro valores:

```text
Unidades procesadas : <cantidad>
Promedio de éxito   : <valor>
Mejor unidad        : <nombre>
Misiones totales    : <cantidad>
```

Construir el comando necesario para ejecutar `code/squadron_registry` utilizando `tests/test001.in` como `stdin`. Para entregar el archivo al programa, utilizar el operador `<` de la misma forma que en los laboratorios anteriores.

Comparar el resultado con `tests/test001.expected`. La salida visible ya debería ser correcta. Los problemas pendientes corresponden al manejo interno de la memoria dinámica.

#### 3.2. Ejecutar la suite funcional

Revisar los permisos de `scripts/tests-run.sh` y agregar permiso de ejecución para el propietario si es necesario.

El script recibe dos argumentos, en este orden:

```text
tests-run.sh <RUTA_AL_EJECUTABLE> <DIRECTORIO_DE_TESTS>
```

Construir el comando necesario para ejecutar desde `workspace` los cuatro casos de `tests` sobre `code/squadron_registry`.

Los cuatro casos deberían entregar `PASS` antes de corregir los problemas de memoria. Esto demuestra que comparar `stdout` con los resultados esperados no basta para validar el manejo de memoria de un programa.

#### 3.3. Analizar directamente un test case

Adaptar el comando utilizado en 2.3 para analizar `code/squadron_registry` con Valgrind. Incorporar las opciones indicadas a continuación y utilizar `tests/test001.in` como entrada mediante `<`:

- `--tool=memcheck` selecciona la herramienta de análisis de memoria.
- `--leak-check=full` incluye la secuencia de llamadas asociada a cada reserva no liberada.
- `--show-leak-kinds=all` muestra todas las categorías de memoria no liberada.
- `--track-origins=yes` agrega el origen de los valores indefinidos.

Leer el informe y ubicar:

- La cantidad de memoria que permanece reservada cuando termina el programa.
- La función y la línea de código asociadas a la reserva.
- La categoría informada por Valgrind.
- La secuencia de llamadas que condujo a la reserva.

No corregir todavía el programa. Primero comprobar que se puede encontrar en `squadron_registry.c` la línea informada por Valgrind.

#### 3.4. Ejecutar todos los casos con Valgrind

El script `valgrind-run.sh` automatiza para cada test case el análisis realizado manualmente en 3.3. Para cada archivo `test<NNN>.in`, el script:

1. Busca el archivo `test<NNN>.expected` correspondiente.
2. Ejecuta el programa con las mismas opciones de Valgrind utilizadas en 3.3.
3. Entrega el archivo `.in` al programa mediante `stdin`.
4. Guarda la salida del programa en `test<NNN>.out` y el informe de Valgrind en `test<NNN>.vg`.
5. Comprueba que Valgrind no informe problemas de memoria.
6. Compara la salida obtenida con el resultado esperado.
7. Informa el resultado del test case como `PASS`, `FAIL` o `ERRO`.

Los resultados se interpretan de la siguiente forma:

- `PASS`: el programa termina correctamente, no presenta problemas de memoria y su salida coincide con el resultado esperado.
- `FAIL`: el programa termina correctamente, pero presenta un problema de memoria o produce una salida diferente.
- `ERRO`: el programa no puede ejecutarse correctamente o falta un archivo necesario para realizar la prueba.

Revisar los permisos de `scripts/valgrind-run.sh` y agregar permiso de ejecución para el propietario si es necesario.

El script utiliza la misma interfaz que `tests-run.sh`:

```text
valgrind-run.sh <RUTA_AL_EJECUTABLE> <DIRECTORIO_DE_TESTS>
```

Construir el comando necesario para analizar con Valgrind los cuatro casos de `tests` sobre `code/squadron_registry`.

Cuando un caso falla, el script conserva un archivo `testNNN.vg` con el informe completo de Valgrind. Abrir el informe correspondiente con Vim antes de modificar el programa.

#### 3.5. Interpretar y corregir los problemas

Los informes de Valgrind pueden clasificar la memoria no liberada en cuatro categorías:

- `definitely lost`: no queda disponible un puntero que permita liberar el bloque reservado.
- `indirectly lost`: un bloque solo puede alcanzarse mediante otro bloque que ya se perdió. El informe también muestra como `definitely lost` el bloque que contenía el puntero.
- `possibly lost`: Valgrind encuentra un puntero al interior del bloque, pero no puede comprobar que su dirección inicial siga disponible.
- `still reachable`: todavía existe un puntero válido al terminar el programa, pero el bloque no fue liberado explícitamente.

Utilizar la secuencia de llamadas de cada informe `.vg` para encontrar la función correspondiente. La categoría describe el estado de los punteros cuando termina el programa, pero no indica directamente qué corrección debe realizarse.

El resumen de errores no basta por sí solo, ya que puede quedar memoria clasificada como `still reachable` sin que exista un acceso inválido.

Trabajar cada caso mediante el siguiente procedimiento:

1. Abrir el informe `.vg` correspondiente.
2. Encontrar la reserva en `squadron_registry.c`.
3. Determinar qué parte del programa es responsable de la memoria reservada.
4. Incorporar la liberación necesaria sin modificar el resultado funcional.
5. Volver a compilar el programa.
6. Ejecutar la suite funcional.
7. Ejecutar la suite de Valgrind y comprobar que el caso corregido entrega `PASS`.

Corregir un caso a la vez. Un cambio pequeño seguido por ambas suites permite comprobar que se resolvió el problema previsto sin alterar el comportamiento del programa.

### 4. Verificación final

Revisar los permisos de `scripts/check.sh` y agregar permiso de ejecución para el propietario si es necesario.

Ejecutar `scripts/check.sh` desde `workspace`.

El script permite revisar cuáles actividades fueron completadas y cuáles se encuentran pendientes.
