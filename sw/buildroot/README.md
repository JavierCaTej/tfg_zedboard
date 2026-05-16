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

La build de Buildroot ya incorpora la personalización de `T8` y el flujo de SD estable:

- parches del kernel aplicados desde `BR2_GLOBAL_PATCH_DIR`
- `dtsi` propio con el nodo de `tfg_axi_lite_regs`
- `dtb` regenerado con el periférico en `0x40000000`
- `rootfs-overlay` reservado para configuración, scripts y pruebas del proyecto
- `post-image.sh` propio para construir la partición `boot` de la SD
- `genimage.cfg` propio con `boot.bin`, `u-boot.img`, `uImage`, `system.dtb`, `extlinux.conf` y el bitstream
- fragmento de U-Boot `uboot/bootcmd.config` para cargar automáticamente la PL antes de Linux

Con esto, la salida de `sw/buildroot/output/zedboard/` ya representa la base Linux actual del TFG y puede volver a sincronizarse de forma repetible hacia `artifacts/buildroot/`.

## Personalización de placa

La personalización específica del proyecto se encuentra en  `sw/buildroot/board/tfg_zedboard/`:

- `dts/`: definición propia del nodo AXI-Lite
- `genimage.cfg`: composición de la imagen SD estable
- `patches/linux/`: parches aplicados al árbol del kernel
- `post-image.sh`: script final de Buildroot que añade el bitstream y genera la imagen SD
- `rootfs-overlay/`: ficheros que Buildroot copiará dentro del rootfs final
- `scripts/` y `tests/`: espacio reservado para utilidades auxiliares del proyecto
- `uboot/`: fragmentos de configuración de U-Boot usados por Buildroot

## Artefactos congelados

Los artefactos relevantes de la build actual se copian a `artifacts/buildroot/` para conservar una salida trazable del sistema Linux:

- `u-boot.elf`: ELF de U-Boot generado por Buildroot.
- `boot-spl.bin`: primer cargador activo generado por U-Boot SPL.
- `u-boot.img`: segunda etapa activa de U-Boot, con `bootcmd` propio para cargar la PL.
- `tfg_zedboard_bd_wrapper.bit`: bitstream incluido en la partición `boot`.
- `uImage`: kernel Linux en formato U-Boot legacy image.
- `system.dtb`: DTB usado por el arranque, ya adaptado al periférico del proyecto.
- `zynq-zed.dtb`: device tree de ZedBoard regenerado con el nodo AXI-Lite añadido.
- `rootfs.ext4`: root filesystem base.
- `rootfs.tar`: root filesystem en formato tar para inspección o reutilización.
- `sdcard.img`: imagen SD completa generada por Buildroot.
- `extlinux.conf`: configuración de arranque usada en la partición boot.

El `BOOT.bin` generado en `T6` se conserva como artefacto de diagnóstico del flujo FSBL. La SD estable usa el flujo `U-Boot SPL` generado por Buildroot:

```text
BootROM -> boot-spl.bin -> u-boot.img -> carga de bitstream -> Linux
```

La carga automática del bitstream queda fijada en `sw/buildroot/board/tfg_zedboard/uboot/bootcmd.config`.
