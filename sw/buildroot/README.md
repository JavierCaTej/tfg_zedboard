# Buildroot

En esta carpeta mantengo el árbol fuente de Buildroot, la configuración propia del proyecto y el directorio de salida out-of-tree. El objetivo es construir de forma reproducible los artefactos Linux de la ZedBoard sin mezclar la salida generada con el árbol fuente.

## Rutas usadas

- Árbol fuente: `sw/buildroot/buildroot-2023.02.9/`
- Configuración del proyecto: `sw/buildroot/configs/tfg_zedboard_defconfig`
- Directorio de salida: `sw/buildroot/output/zedboard/`
- Script de invocación: `sw/buildroot/scripts/build_buildroot.sh`
- Directorio de placa del proyecto: `sw/buildroot/board/tfg_zedboard/`

## Uso del script

El script fija automáticamente:

- la versión de Buildroot usada en el proyecto
- el directorio `O=` de salida
- la defconfig propia del proyecto

Comandos habituales:

```bash
./sw/buildroot/scripts/build_buildroot.sh project-defconfig
```

Carga la configuración propia del proyecto desde `sw/buildroot/configs/tfg_zedboard_defconfig`.

```bash
./sw/buildroot/scripts/build_buildroot.sh menuconfig
```

Abre la configuración interactiva de Buildroot sobre el árbol de salida actual.

```bash
./sw/buildroot/scripts/build_buildroot.sh olddefconfig
```

Regenera `.config` aplicando los valores por defecto que falten tras cambiar opciones o actualizar la defconfig.

```bash
./sw/buildroot/scripts/build_buildroot.sh savedefconfig BR2_DEFCONFIG=/home/javier/tfg/tfg_zedboard/sw/buildroot/configs/tfg_zedboard_defconfig
```

Guarda la configuración mínima actual en la defconfig propia del proyecto.

```bash
./sw/buildroot/scripts/build_buildroot.sh
```

Lanza la build completa con la configuración ya cargada en `sw/buildroot/output/zedboard/`.

## Orden recomendado

Para trabajar de forma ordenada sigo este flujo:

```bash
./sw/buildroot/scripts/build_buildroot.sh project-defconfig
./sw/buildroot/scripts/build_buildroot.sh menuconfig
./sw/buildroot/scripts/build_buildroot.sh olddefconfig
./sw/buildroot/scripts/build_buildroot.sh savedefconfig BR2_DEFCONFIG=/home/javier/tfg/tfg_zedboard/sw/buildroot/configs/tfg_zedboard_defconfig
./sw/buildroot/scripts/build_buildroot.sh
```

Si no necesito cambiar la configuración, basta con relanzar directamente:

```bash
./sw/buildroot/scripts/build_buildroot.sh
```

Después de una build, sincronizo las salidas relevantes con `artifacts/buildroot/` mediante:

```bash
./sw/buildroot/scripts/sync_buildroot_artifacts.sh
```

## Estado actual

La build de Buildroot ya incorpora la personalización básica de `T8`:

- parches del kernel aplicados desde `BR2_GLOBAL_PATCH_DIR`
- `dtsi` propio con el nodo de `tfg_axi_lite_regs`
- `dtb` regenerado con el periférico en `0x40000000`
- `rootfs-overlay` reservado para configuración, scripts y pruebas del proyecto

Con esto, la salida de `sw/buildroot/output/zedboard/` ya representa la base Linux actual del TFG y puede volver a sincronizarse de forma repetible hacia `artifacts/buildroot/`.

## Personalización de placa

La personalización específica del proyecto se encuentra en  `sw/buildroot/board/tfg_zedboard/`:

- `dts/`: definición propia del nodo AXI-Lite
- `patches/linux/`: parches aplicados al árbol del kernel
- `rootfs-overlay/`: ficheros que Buildroot copiará dentro del rootfs final
- `scripts/` y `tests/`: espacio reservado para utilidades auxiliares del proyecto

## Artefactos congelados

Los artefactos relevantes de la build actual se copian a `artifacts/buildroot/` para conservar una salida trazable del sistema Linux:

- `u-boot.elf`: ELF de U-Boot generado por Buildroot.
- `uImage`: kernel Linux en formato U-Boot legacy image.
- `system.dtb`: DTB usado por el arranque, ya adaptado al periférico del proyecto.
- `zynq-zed.dtb`: device tree de ZedBoard regenerado con el nodo AXI-Lite añadido.
- `rootfs.ext4`: root filesystem base.
- `rootfs.tar`: root filesystem en formato tar para inspección o reutilización.
- `sdcard.img`: imagen SD completa generada por Buildroot.
- `extlinux.conf`: configuración de arranque usada en la partición boot.

El `BOOT.bin` final del proyecto no se cierra en esta tarea. Se generará al volver a `T6`, usando el `FSBL`, el bitstream de Vivado y `artifacts/buildroot/u-boot.elf`.
