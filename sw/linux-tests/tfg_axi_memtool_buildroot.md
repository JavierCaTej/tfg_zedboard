# Actualizar `tfg_axi_memtool` en Buildroot

Este documento explica el flujo que sigo para actualizar la utilidad `tfg_axi_memtool` cuando cambio su código fuente y quiero que el nuevo binario quede incluido en la imagen SD generada por Buildroot.

## Punto de partida

El código fuente está en:

```text
sw/linux-tests/tfg_axi_memtool.c
```

El binario que Buildroot copia al root filesystem está en el `rootfs-overlay`:

```text
sw/buildroot/board/tfg_zedboard/rootfs-overlay/usr/local/bin/tfg_axi_memtool
```

Cuando Buildroot genera la `rootfs`, copia el contenido de `rootfs-overlay/` respetando la misma estructura de directorios. Por tanto, ese binario aparecerá en la ZedBoard como:

```text
/usr/local/bin/tfg_axi_memtool
```

## Flujo de actualización

### 1. Modificar el código fuente

Edito la utilidad en:

```text
sw/linux-tests/tfg_axi_memtool.c
```

Si cambio offsets, máscaras o valores esperados del periférico, también debo revisar:

```text
sw/include/tfg_axi_lite_regs.h
```

Ese header es el contrato software del mapa de registros, por lo que debe seguir coincidiendo con el IP hardware.

### 2. Compilar la utilidad para la ZedBoard

Desde la raíz del repositorio:

```bash
make -C sw/linux-tests
```

El `Makefile` usa por defecto el compilador cruzado generado por Buildroot:

```text
sw/buildroot/output/zedboard/host/bin/arm-buildroot-linux-gnueabihf-gcc
```

El resultado local es:

```text
sw/linux-tests/tfg_axi_memtool
```

Este fichero es un binario ARM para la ZedBoard. No es un binario para ejecutar en el host.

### 3. Instalar el binario en el `rootfs-overlay`

Para evitar copiar a mano el binario, uso el script:

```bash
./sw/linux-tests/install_to_rootfs_overlay.sh
```

Este script hace dos cosas:

- Compila `tfg_axi_memtool` usando el `Makefile`.
- Copia el binario resultante a `sw/buildroot/board/tfg_zedboard/rootfs-overlay/usr/local/bin/tfg_axi_memtool` con permisos de ejecución.

Después de este paso, el overlay ya contiene la versión actualizada de la utilidad.

### 4. Regenerar la imagen de Buildroot

Para que el binario entre realmente en la SD, no basta con actualizar el overlay. Hay que regenerar la salida de Buildroot:

```bash
./sw/buildroot/scripts/build_buildroot.sh
```

Buildroot reconstruirá la `rootfs` y volverá a generar las imágenes finales usando el contenido actual del `rootfs-overlay`.

### 5. Sincronizar artefactos

Después de construir Buildroot, actualizo la carpeta `artifacts/buildroot/`:

```bash
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

El artefacto principal que tengo que grabar en la SD es:

```text
artifacts/buildroot/sdcard.img
```

### 6. Probar en la ZedBoard

Después de grabar la nueva `sdcard.img`, la utilidad debería estar disponible directamente en Linux:

```bash
tfg_axi_memtool smoke
```

Prueba funcional mínima esperada:

```bash
tfg_axi_memtool read 0x00
```

El valor esperado para `REG_ID` es:

```text
0x54464700
```

Una primera medida básica se puede lanzar con:

```bash
tfg_axi_memtool rw-loop --iters 100000 --warmup 1000 --csv --build-id t10-baseline
```

El campo importante para la comprobación funcional es:

```text
mismatches=0
```

## Comandos resumidos

Flujo completo desde la raíz del repositorio:

```bash
./sw/linux-tests/install_to_rootfs_overlay.sh
./sw/buildroot/scripts/build_buildroot.sh
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

Después se graba:

```text
artifacts/buildroot/sdcard.img
```

Y en la ZedBoard se valida:

```bash
tfg_axi_memtool smoke
tfg_axi_memtool rw-loop --iters 100000 --warmup 1000 --csv --build-id t10-baseline
```

## Criterio para considerar actualizado el binario

Considero que `tfg_axi_memtool` está actualizado en Buildroot cuando se cumplen estos puntos:

- El código fuente nuevo compila sin errores.
- El binario ARM actualizado está en el `rootfs-overlay`.
- Buildroot ha regenerado la `sdcard.img`.
- La ZedBoard arranca con esa imagen.
- `tfg_axi_memtool smoke` funciona desde `/usr/local/bin`.
- Una prueba `rw-loop` termina con `mismatches=0`.

Con la SD estable ya validada y el binario incluido en el `rootfs-overlay`, este flujo queda cerrado como parte de `T10`.
