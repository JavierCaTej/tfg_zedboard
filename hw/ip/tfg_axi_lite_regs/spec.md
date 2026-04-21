# Especificación inicial del IP `tfg_axi_lite_regs`

## Propósito

`tfg_axi_lite_regs` es un periférico esclavo `AXI4-Lite` sencillo orientado a:

- validar la comunicación `PS -> PL` en ZedBoard;
- exponer un conjunto mínimo de registros legibles y escribibles desde Linux;
- servir como base para pruebas funcionales y medidas de latencia de acceso a registros.

Este IP forma parte del MVP del TFG y prioriza simplicidad, trazabilidad y comportamiento fácilmente verificable desde espacio de usuario.

## Identidad del IP

- Nombre del IP: `tfg_axi_lite_regs`
- Tipo de interfaz: esclavo `AXI4-Lite`
- Ancho de datos: `32 bits`
- Acceso software previsto: lecturas y escrituras de `32 bits` alineadas a palabra
- Camino de acceso previsto: `PS master -> PL slave`

## Reglas de direccionamiento

- Los offsets válidos del mapa de registros estarán alineados a palabra de `32 bits`.
- Los offsets definidos seguirán el patrón `0x00`, `0x04`, `0x08`, `0x0C`, ...
- No se definen offsets impares ni semánticas implícitas sobre bytes o medias palabras.
- El software accederá a los registros mediante operaciones `read32(offset)` y `write32(offset, value)`.

## Ventana de mapeo

- La dirección base del periférico queda pendiente de asignación en Vivado `Address Editor`.
- El tamaño de la ventana de mapeo queda pendiente de confirmación en Vivado.
- Para el MVP se considera como objetivo una ventana limpia y documentada, previsiblemente `0x1000` bytes, siempre que coincida con la región asignada por Vivado.
- El tamaño final deberá reflejarse de forma coherente en Vivado, device tree y software de usuario.

## Mapa de registros inicial

| Offset | Nombre | Acceso | Reset | Descripción |
|---|---|---|---|---|
| `0x00` | `REG_ID` | `RO` | `0x54464700` | Identificador constante del periférico para validar el mapeo correcto. |
| `0x04` | `REG_VERSION` | `RO` | `0x00010000` | Versión del IP para comprobar coherencia entre hardware y software. |
| `0x08` | `REG_CONTROL` | `RW` | `0x00000000` | Registro de control mínimo. |
| `0x0C` | `REG_STATUS` | `RO` | `0x00000000` | Estado básico del periférico. |
| `0x10` | `REG_WDATA` | `RW` | `0x00000000` | Dato de prueba escrito desde Linux. |
| `0x14` | `REG_RDATA` | `RO` | `0x00000000` | Dato devuelto por el periférico. |
| `0x18` | `REG_WRITE_COUNT` | `RO` | `0x00000000` | Contador de escrituras válidas. |
| `0x1C` | `REG_READ_COUNT` | `RO` | `0x00000000` | Contador de lecturas válidas. |

## Semántica funcional inicial

### `REG_ID`

- Registro de solo lectura.
- Contendrá una constante fija que permita verificar que el software está accediendo al periférico correcto.
- Valor fijado: `0x54464700`, correspondiente a `"TFG\0"` en ASCII.

### `REG_VERSION`

- Registro de solo lectura.
- Contendrá una codificación simple de versión del IP con formato `0x00MMmmpp`.
- Asignación:
  - bits `[23:16]`: versión major
  - bits `[15:8]`: versión minor
  - bits `[7:0]`: versión patch
- Valor inicial fijado: `0x00010000`, correspondiente a versión `1.0.0`.

### `REG_CONTROL`

- Registro de lectura/escritura.
- Se reserva para acciones de control mínimas del MVP.
- Asignación de bits:
  - bit `0`: `CLEAR_COUNTERS`
  - bits `[31:1]`: reservados
- Escribir un `1` en `CLEAR_COUNTERS` solicita el borrado de `REG_WRITE_COUNT` y `REG_READ_COUNT`.
- Los bits reservados deberán escribirse a `0`.
- El valor tras reset será `0x00000000`.

### `REG_STATUS`

- Registro de solo lectura.
- Reflejará el estado básico del periférico.
- Asignación de bits:
  - bit `0`: `READY`
  - bits `[31:1]`: reservados
- `READY` valdrá `1` cuando el periférico esté operativo.
- Los bits reservados deberán leerse como `0`.
- El valor tras reset será `0x00000000`.

### `REG_WDATA`

- Registro de lectura/escritura.
- Almacena el dato de prueba escrito desde software.
- El valor tras reset será `0x00000000`.

### `REG_RDATA`

- Registro de solo lectura.
- Para el MVP devolverá eco exacto del último valor válido escrito en `REG_WDATA`.
- El valor tras reset será `0x00000000`.

### `REG_WRITE_COUNT`

- Registro de solo lectura.
- Cuenta escrituras válidas realizadas sobre `REG_WDATA`.
- El valor tras reset será `0x00000000`.

### `REG_READ_COUNT`

- Registro de solo lectura.
- Cuenta lecturas válidas realizadas sobre `REG_RDATA`.
- El valor tras reset será `0x00000000`.

## Política de errores

- Si se utiliza una plantilla `AXI4-Lite` generada por Vivado, se mantendrá su comportamiento por defecto y se documentará explícitamente en la implementación.
- Si se implementa lógica propia para offsets no definidos:
  - una lectura sobre un offset no implementado devolverá `0x00000000`;
  - una escritura sobre un offset no implementado se ignorará;
  - no se producirán efectos laterales sobre registros válidos.

## Contrato con software

- El software de validación deberá leer `REG_ID` antes de iniciar pruebas de humo o campañas de medida.
- La dirección base no se fijará de forma aislada en el software: deberá venir del diseño hardware y quedar reflejada en el device tree.
- La semántica de los registros deberá permanecer estable una vez cerrada esta especificación.

## Pendientes para la siguiente revisión

- Confirmar dirección base y tamaño final de ventana en Vivado.
